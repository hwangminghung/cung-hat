import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/plan_providers.dart';
import '../data/plan_repository.dart';
import '../domain/venue_suggestion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/hard_card.dart';
import '../../../shared/widgets/responsive_frame.dart';
import '../../../shared/widgets/skeleton.dart';
import 'booking_button.dart';
import 'plan_time_picker_sheet.dart';
import 'safety_toolkit.dart';
import 'venue_map_surface.dart';

/// Cổng đặt cọc chỉ bật khi build với --dart-define=BOOKING_ENABLED=true
/// (quyết định payments-v1 2026-07-10: v1 không thanh toán).
const bookingEnabled = bool.fromEnvironment('BOOKING_ENABLED');

const planSectionPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.lg,
  vertical: AppSpacing.sm,
);

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

  String _statusLabel(String status, AppLocalizations? l10n) {
    switch (status) {
      case 'confirmed':
        return l10n?.planStatusConfirmed ?? 'Đã chốt';
      case 'proposed':
        return l10n?.planStatusProposed ?? 'Chờ đồng ý';
      default:
        return status;
    }
  }

  String _venueName(
    List<VenueSuggestion> venues,
    String venueId,
    AppLocalizations? l10n,
  ) {
    for (final v in venues) {
      if (v.id == venueId) return v.name;
    }
    return l10n?.planVenuePicked ?? 'Quán đã chọn';
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
      appBar: AppBar(
        title: Text(
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.planTitle ??
              'Kế hoạch',
        ),
      ),
      body: ResponsiveFrame(
        child: KeyedSubtree(
          key: const Key('screen_19_plan'),
          child: ListView(
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
                loading: () => const SkeletonCard(),
                error: (e, _) => const SizedBox.shrink(),
              ),
              // Current plan section
              planAsync.when(
                data: (plan) => plan == null
                    ? const SizedBox.shrink()
                    : _buildPlanCard(context, ref, plan, venues),
                loading: () => const SkeletonCard(),
                error: (e, _) => EmptyState(
                  icon: Icons.event_busy_outlined,
                  title:
                      Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.planLoadError ??
                      'Không tải được kế hoạch',
                  subtitle:
                      Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.commonCheckConnection ??
                      'Kiểm tra kết nối rồi thử lại.',
                  actionLabel:
                      Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.planReload ??
                      'Tải lại',
                  onAction: () => ref.invalidate(currentPlanProvider(keoId)),
                ),
              ),
              // Venue suggestions section
              venuesAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    final l10n = Localizations.of<AppLocalizations>(
                      context,
                      AppLocalizations,
                    );
                    return EmptyState(
                      key: const Key('venues_empty_state'),
                      icon: Icons.place_outlined,
                      title: l10n?.planNoVenuesTitle ?? 'Chưa có quán gợi ý',
                      subtitle:
                          l10n?.planNoVenuesSub ??
                          'Khi có dữ liệu quán từ Places hoặc seed, bản đồ sẽ hiển thị marker để chọn điểm hẹn.',
                      actionLabel: l10n?.planReload ?? 'Tải lại',
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
                loading: () => const SkeletonCard(),
                error: (e, _) => EmptyState(
                  icon: Icons.location_off_outlined,
                  title:
                      Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.planVenuesLoadError ??
                      'Không tải được danh sách quán',
                  subtitle:
                      Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.commonCheckConnection ??
                      'Kiểm tra kết nối rồi thử lại.',
                  actionLabel:
                      Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.planReload ??
                      'Tải lại',
                  onAction: () {
                    ref.invalidate(nearestVenuesProvider(keoId));
                    ref.invalidate(keoMidpointProvider(keoId));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref,
    Plan plan,
    List<VenueSuggestion> venues,
  ) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final name = _venueName(venues, plan.venueId, l10n);
    return Padding(
      padding: planSectionPadding,
      child: HardCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.planTime(plan.scheduledAt) ??
                    'Thời gian: ${plan.scheduledAt}',
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.planStatus(_statusLabel(plan.status, l10n)) ??
                    'Trạng thái: ${_statusLabel(plan.status, l10n)}',
              ),
              const SizedBox(height: 12),
              if (plan.status != 'confirmed')
                FilledButton(
                  key: const Key('confirm_plan_btn'),
                  child: Text(l10n?.planConfirmCta ?? 'Đồng ý kế hoạch'),
                  onPressed: () async {
                    try {
                      await ref
                          .read(planRepositoryProvider)
                          .confirmPlan(plan.id);
                      ref.invalidate(currentPlanProvider(keoId));
                    } catch (_) {
                      if (context.mounted) {
                        _snack(
                          context,
                          l10n?.planConfirmError ?? 'Không đồng ý được',
                        );
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
                        _snack(
                          context,
                          l10n?.planMapError ?? 'Không mở được bản đồ',
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        _snack(
                          context,
                          l10n?.planMapError ?? 'Không mở được bản đồ',
                        );
                      }
                    }
                  },
                  child: Text(l10n?.planDirections ?? 'Chỉ đường'),
                ),
                const SizedBox(height: 12),
                SafetyToolkit(planId: plan.id),
              ],
            ],
          ),
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
    return Padding(
      padding: planSectionPadding,
      child: HardCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(v.address),
              const SizedBox(height: 4),
              Text(
                Localizations.of<AppLocalizations>(
                      context,
                      AppLocalizations,
                    )?.planSuggestReason(band) ??
                    'Gợi ý vì gần điểm cân bằng cả nhóm · cách $band km',
              ),
              if (isHost) ...[
                const SizedBox(height: 8),
                TextButton(
                  key: Key('pick_venue_${v.id}'),
                  child: Text(
                    Localizations.of<AppLocalizations>(
                          context,
                          AppLocalizations,
                        )?.planPickVenue ??
                        'Chọn quán này',
                  ),
                  onPressed: () => _pickVenue(context, ref, v),
                ),
              ],
            ],
          ),
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
        _snack(
          context,
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.planProposed ??
              'Đã đề xuất kế hoạch',
        );
      }
    } catch (_) {
      if (context.mounted) {
        _snack(
          context,
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.planProposeError ??
              'Không đề xuất được',
        );
      }
    }
  }
}
