import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/plan_providers.dart';
import '../data/plan_repository.dart';
import '../domain/venue_suggestion.dart';
import 'safety_toolkit.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key, required this.keoId, required this.isHost});

  final String keoId;
  final bool isHost;

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Đã chốt';
      case 'proposed':
        return 'Chờ đồng ý';
      default:
        return status;
    }
  }

  String _venueName(List<VenueSuggestion> venues, String venueId) {
    for (final v in venues) {
      if (v.id == venueId) return v.name;
    }
    return 'Quán đã chọn';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentPlanProvider(keoId));
    final venuesAsync = ref.watch(nearestVenuesProvider(keoId));
    final venues = venuesAsync.asData?.value ?? const <VenueSuggestion>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Kế hoạch')),
      body: ListView(
        children: [
          // Current plan section
          planAsync.when(
            data: (plan) => plan == null
                ? const SizedBox.shrink()
                : _buildPlanCard(context, ref, plan, venues),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Không tải được kế hoạch'),
            ),
          ),
          // Venue suggestions section
          venuesAsync.when(
            data: (list) => Column(
              children: [
                for (final v in list) _buildVenueCard(context, ref, v),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Không tải được danh sách quán'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, Plan plan,
      List<VenueSuggestion> venues) {
    final name = _venueName(venues, plan.venueId);
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Thời gian: ${plan.scheduledAt}'),
            const SizedBox(height: 4),
            Text('Trạng thái: ${_statusLabel(plan.status)}'),
            const SizedBox(height: 12),
            if (plan.status != 'confirmed')
              FilledButton(
                key: const Key('confirm_plan_btn'),
                child: const Text('Đồng ý kế hoạch'),
                onPressed: () async {
                  try {
                    await ref.read(planRepositoryProvider).confirmPlan(plan.id);
                    ref.invalidate(currentPlanProvider(keoId));
                  } catch (_) {
                    if (context.mounted) {
                      _snack(context, 'Không đồng ý được');
                    }
                  }
                },
              )
            else
              SafetyToolkit(planId: plan.id),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context, WidgetRef ref, VenueSuggestion v) {
    final band = v.distanceBand ?? '?';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(v.address),
            const SizedBox(height: 4),
            Text('Gợi ý vì gần điểm cân bằng cả nhóm · cách $band km'),
            if (isHost) ...[
              const SizedBox(height: 8),
              TextButton(
                child: const Text('Chọn quán này'),
                onPressed: () => _pickVenue(context, ref, v),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickVenue(
      BuildContext context, WidgetRef ref, VenueSuggestion v) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    try {
      await ref.read(planRepositoryProvider).proposePlan(keoId, v.id, when);
      ref.invalidate(currentPlanProvider(keoId));
      if (context.mounted) {
        _snack(context, 'Đã đề xuất kế hoạch');
      }
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'Không đề xuất được');
      }
    }
  }
}
