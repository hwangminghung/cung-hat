import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../application/plan_providers.dart';
import '../data/plan_repository.dart';
import '../domain/venue_suggestion.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'booking_button.dart';
import 'plan_time_picker_sheet.dart';
import 'safety_toolkit.dart';
import 'venue_map_surface.dart';

/// Cổng đặt cọc chỉ bật khi build với --dart-define=BOOKING_ENABLED=true
/// (quyết định payments-v1 2026-07-10: v1 không thanh toán).
const bookingEnabled = bool.fromEnvironment('BOOKING_ENABLED');

class PlanScreen extends ConsumerWidget {
  const PlanScreen({
    super.key,
    required this.keoId,
    required this.isHost,
    this.useNativeMap = true,
    this.debugNow,
  });

  final String keoId;
  final bool isHost;
  final bool useNativeMap;
  final DateTime? debugNow;

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

  String _venueAddress(List<VenueSuggestion> venues, String? venueId) {
    for (final v in venues) {
      if (v.id == venueId) return v.address;
    }
    return '';
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
          venuesAsync.when(
            data: (list) => VenueMapSurface(
              venues: list,
              midpoint: ref.watch(keoMidpointProvider(keoId)).asData?.value,
              useNativeMap: useNativeMap,
              onVenueSelected: isHost
                  ? (venue) => _pickVenue(context, ref, venue)
                  : (_) {},
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => const SizedBox.shrink(),
          ),
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
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  key: const Key('venues_empty_state'),
                  icon: Icons.place_outlined,
                  title: 'Chưa có quán gợi ý',
                  subtitle:
                      'Khi có dữ liệu quán từ Places hoặc seed, bản đồ sẽ hiển thị marker để chọn điểm hẹn.',
                  actionLabel: 'Tải lại',
                  onAction: () {
                    ref.invalidate(nearestVenuesProvider(keoId));
                    ref.invalidate(keoMidpointProvider(keoId));
                  },
                );
              }
              return Column(
                children: [
                  for (final v in list) _buildVenueCard(context, ref, v),
                ],
              );
            },
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

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref,
    Plan plan,
    List<VenueSuggestion> venues,
  ) {
    final name = _venueName(venues, plan.venueId);
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
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
            else ...[
              if (bookingEnabled) ...[
                BookingButton(planId: plan.id, venueId: plan.venueId),
                const SizedBox(height: 12),
              ],
              GradientButton(
                key: const Key('directions_btn'),
                icon: Icons.place_rounded,
                onPressed: () async {
                  final query = Uri.encodeComponent(
                    '$name ${_venueAddress(venues, plan.venueId)}'.trim(),
                  );
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$query',
                  );
                  try {
                    final ok = await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok && context.mounted) {
                      _snack(context, 'Không mở được bản đồ');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      _snack(context, 'Không mở được bản đồ');
                    }
                  }
                },
                child: const Text('Chỉ đường'),
              ),
              const SizedBox(height: 12),
              SafetyToolkit(planId: plan.id),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVenueCard(
    BuildContext context,
    WidgetRef ref,
    VenueSuggestion v,
  ) {
    final band = v.distanceBand ?? '?';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              v.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(v.address),
            const SizedBox(height: 4),
            Text('Gợi ý vì gần điểm cân bằng cả nhóm · cách $band km'),
            if (isHost) ...[
              const SizedBox(height: 8),
              TextButton(
                key: Key('pick_venue_${v.id}'),
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
    BuildContext context,
    WidgetRef ref,
    VenueSuggestion v,
  ) async {
    final when = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlanTimePickerSheet(
        venueName: v.name,
        now: debugNow ?? DateTime.now(),
      ),
    );
    if (when == null) return;
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
