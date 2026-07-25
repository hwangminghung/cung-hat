import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/datetime_format.dart';
import '../application/plan_providers.dart';
import '../data/plan_repository.dart';
import '../domain/venue_suggestion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/hard_card.dart';
import '../../../shared/widgets/responsive_frame.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../discovery/presentation/report_sheet.dart';
import '../../keo/application/keo_providers.dart';
import '../../keo/domain/keo_member.dart';
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

  /// [AUDIT SAFETY] Man ke hoach truoc day khong co loi bao cao nao, du day
  /// la noi chot dia diem gap mat ngoai doi. Keo co nhieu nguoi ma
  /// report_user/block_user chi nhan MOT user id, nen phai chon dich danh
  /// thanh vien truoc khi mo ReportSheet.
  Future<void> _openSafetySheet(BuildContext context, WidgetRef ref) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    List<KeoMember> roster;
    try {
      roster = await ref.read(keoRosterProvider(keoId).future);
    } catch (_) {
      roster = const <KeoMember>[];
    }
    if (!context.mounted) return;
    String? me;
    try {
      me = ref.read(supabaseClientProvider).auth.currentUser?.id;
    } catch (_) {
      me = null;
    }
    final others = [
      for (final member in roster)
        if (member.userId != me) member,
    ];
    if (others.isEmpty) {
      // Chua co danh sach thanh vien thi khong biet bao cao ai — noi that
      // thay vi mo mot sheet rong.
      _snack(
        context,
        l10n?.chatProfileError ?? 'Không mở được hồ sơ. Thử lại sau.',
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('plan_safety_picker'),
              title: Text(l10n?.safetyPickMember ?? 'Bạn muốn báo cáo ai?'),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final member in others)
                    ListTile(
                      key: Key('plan_safety_member_${member.userId}'),
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        member.displayName ??
                            (l10n?.keoSharedAnonymous ?? 'Ẩn danh'),
                      ),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => ReportSheet(targetId: member.userId),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentPlanProvider(keoId));
    final venuesAsync = ref.watch(nearestVenuesProvider(keoId));
    final venues = venuesAsync.asData?.value ?? const <VenueSuggestion>[];
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.planTitle ??
              'Kế hoạch',
        ),
        actions: [
          IconButton(
            key: const Key('plan_safety_btn'),
            onPressed: () => _openSafetySheet(context, ref),
            icon: const Icon(Icons.shield_outlined),
            tooltip: l10n?.safetyReportTooltip ?? 'Báo cáo hoặc chặn',
          ),
        ],
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
                  // null (khong phai `(_) {}`) de pin thanh hinh trang tri:
                  // chi chu keo moi chot duoc quan.
                  onVenueSelected: isHost
                      ? (venue) => _pickVenue(context, ref, venue)
                      : null,
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
              Builder(
                builder: (context) {
                  // Chuoi tho chi con la duong lui khi server tra ve gia tri
                  // khong parse duoc — luong binh thuong luon co ban dinh dang.
                  final when =
                      formatLocalDateTime(plan.scheduledAt) ?? plan.scheduledAt;
                  return Text(l10n?.planTime(when) ?? 'Thời gian: $when');
                },
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
