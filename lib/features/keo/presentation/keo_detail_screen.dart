import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/pro_upsell_sheet.dart';
import '../../../shared/widgets/responsive_frame.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/ticket_card.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../profile/application/profile_providers.dart';
import '../application/keo_providers.dart';
import '../data/keo_errors.dart';
import '../domain/keo.dart';
import '../domain/keo_member.dart';

const sectionGap = SizedBox(height: AppSpacing.lg);
const fieldGap = SizedBox(height: AppSpacing.md);

class KeoDetailScreen extends ConsumerWidget {
  const KeoDetailScreen({super.key, required this.keoId, required this.title});

  final String keoId;
  final String title;

  String _statusText(KeoMember member, AppLocalizations? l10n) {
    if (member.joinStatus == 'approved' && member.confirmed) {
      return l10n?.keoStatusConfirmedMember ?? 'Đã xác nhận';
    }
    switch (member.joinStatus) {
      case 'approved':
        return l10n?.keoStatusApproved ?? 'Đã duyệt';
      case 'requested':
        return l10n?.keoStatusRequested ?? 'Chờ duyệt';
      case 'confirmed':
        return l10n?.keoStatusConfirmedMember ?? 'Đã xác nhận';
      case 'left':
        return l10n?.keoStatusLeft ?? 'Đã rời';
      case 'declined':
        return l10n?.keoStatusDeclined ?? 'Bị từ chối';
      default:
        return member.joinStatus;
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Derives the caller's own roster row (or null if not a member) — shared by
  /// the AppBar's share-button gate and the body's action panel so both agree
  /// on exactly who counts as "host or approved member".
  KeoMember? _myRow(WidgetRef ref, List<KeoMember> roster) {
    final uid = ref.watch(myProfileProvider).value?.id;
    for (final member in roster) {
      if (member.userId == uid) return member;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(keoRosterProvider(keoId));
    final roster = rosterAsync.value ?? const <KeoMember>[];
    final myRow = _myRow(ref, roster);
    final canShare = myRow?.role == 'host' || myRow?.joinStatus == 'approved';
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.keoDetailTitle ?? 'Chi tiết kèo'),
        actions: [
          if (canShare)
            IconButton.outlined(
              key: const Key('keo_share_btn'),
              tooltip: l10n?.keoDetailShareTooltip ?? 'Chia sẻ kèo',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _shareKeo(context, ref),
            ),
        ],
      ),
      body: ResponsiveFrame(
        child: KeyedSubtree(
          key: const Key('screen_14_keo_detail'),
          child: rosterAsync.when(
            data: (roster) => _buildBody(context, ref, roster),
            loading: () => ListView(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              children: const [SkeletonTile(), SkeletonTile(), SkeletonTile()],
            ),
            error: (e, _) => EmptyState(
              icon: Icons.wifi_off_rounded,
              title: l10n?.keoSharedLoadError ?? 'Không tải được kèo',
              subtitle:
                  l10n?.commonCheckConnection ??
                  'Kiểm tra kết nối rồi thử lại.',
              actionLabel: l10n?.commonRetry ?? 'Thử lại',
              onAction: () => ref.invalidate(keoRosterProvider(keoId)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareKeo(BuildContext context, WidgetRef ref) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    try {
      final token = await ref
          .read(keoRepositoryProvider)
          .createKeoShareLink(keoId);
      final link = 'cunghat://keo/shared/$token';
      await SharePlus.instance.share(
        ShareParams(
          text:
              l10n?.keoDetailShareMessage(title, link) ??
              'Kèo "$title" đang tuyển giọng ca — vào Cùng Hát xin một chỗ: $link',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.keoDetailShareError ?? 'Không tạo được liên kết, thử lại.',
            ),
          ),
        );
      }
    }
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<KeoMember> roster,
  ) {
    final myRow = _myRow(ref, roster);
    final isHost = myRow?.role == 'host';
    final isApproved = myRow?.joinStatus == 'approved';
    final isConfirmed = myRow?.confirmed ?? false;
    final notMember = myRow == null || myRow.joinStatus == 'left';
    final approvedCount = roster
        .where((member) => member.joinStatus == 'approved')
        .length;
    final headerInfo = ref.watch(keoHeaderProvider(keoId)).value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        _Header(title: title, count: approvedCount, info: headerInfo),
        sectionGap,
        _RosterHeader(
          title:
              Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.keoDetailMembers ??
              'Thành viên',
        ),
        fieldGap,
        for (final member in roster)
          _RosterTile(
            key: ValueKey(member.userId),
            member: member,
            statusText: _statusText(
              member,
              Localizations.of<AppLocalizations>(context, AppLocalizations),
            ),
            isHostViewer: isHost,
            onApprove: () => _approve(context, ref, member),
            onDecline: () => _decline(context, ref, member),
          ),
        sectionGap,
        _ActionPanel(
          notMember: notMember,
          isApproved: isApproved,
          isConfirmed: isConfirmed,
          isHost: isHost,
          onRequestJoin: () => _requestJoin(context, ref),
          onConfirm: () => _confirm(context, ref),
          onOpenChat: () => context.push('/keo/chat/$keoId'),
          onPlan: () => isHost
              ? context.push('/keo/plan/$keoId?host=1')
              : context.push('/keo/plan/$keoId'),
          onLeave: () => _leave(context, ref),
        ),
      ],
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    KeoMember member,
  ) async {
    try {
      await ref.read(keoRepositoryProvider).approve(keoId, member.userId);
      ref.invalidate(keoRosterProvider(keoId));
    } catch (_) {
      if (context.mounted) {
        _snack(
          context,
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.keoDetailApproveError ??
              'Không duyệt được',
        );
      }
    }
  }

  Future<void> _decline(
    BuildContext context,
    WidgetRef ref,
    KeoMember member,
  ) async {
    try {
      await ref.read(keoRepositoryProvider).decline(keoId, member.userId);
      ref.invalidate(keoRosterProvider(keoId));
    } catch (_) {
      if (context.mounted) {
        _snack(
          context,
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.keoDetailDeclineError ??
              'Không từ chối được',
        );
      }
    }
  }

  Future<void> _requestJoin(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(keoRepositoryProvider).requestJoin(keoId);
      unawaited(ref.read(analyticsProvider).logKeoJoinRequest());
      ref.invalidate(keoRosterProvider(keoId));
    } catch (e) {
      if (!context.mounted) return;
      if (keoErrorCode(e) == 'free_join_limit') {
        ProUpsellSheet.show(context, variant: ProUpsellVariant.keoJoinLimit);
      } else {
        _snack(
          context,
          keoErrorMessage(
            e,
            Localizations.of<AppLocalizations>(context, AppLocalizations),
          ),
        );
      }
    }
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(keoRepositoryProvider).confirm(keoId);
      ref.invalidate(keoRosterProvider(keoId));
    } catch (_) {
      if (context.mounted) {
        _snack(
          context,
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.keoDetailConfirmError ??
              'Không xác nhận được',
        );
      }
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(keoRepositoryProvider).leave(keoId);
      ref.invalidate(keoRosterProvider(keoId));
    } catch (_) {
      if (context.mounted) {
        _snack(
          context,
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.keoDetailLeaveError ??
              'Không rời kèo được',
        );
      }
    }
  }
}

class _RosterHeader extends StatelessWidget {
  const _RosterHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final heading = Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    if (textScale > 1.3) {
      return heading;
    }
    return Row(
      children: [
        Flexible(child: heading),
        const SizedBox(width: AppSpacing.md),
        const Expanded(child: WaveDivider()),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.count, this.info});

  final String title;
  final int count;

  /// Giờ + khu vực từ get_keo_header (mockup 14) — null (đang tải/bị chặn)
  /// thì giữ layout cũ chỉ có tiêu đề + số người.
  final Keo? info;

  /// 'HH:mm – HH:mm · d/M' giờ máy — cùng cách quy đổi toLocal như KeoCard.
  static String? _timeLabel(Keo info) {
    final start = DateTime.tryParse(info.timeWindowStart ?? '');
    final end = DateTime.tryParse(info.timeWindowEnd ?? '');
    if (start == null || end == null) return null;
    final s = start.toLocal();
    final e = end.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s.hour)}:${two(s.minute)} – ${two(e.hour)}:${two(e.minute)}'
        ' · ${s.day}/${s.month}';
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = info == null ? null : _timeLabel(info!);
    final areaLabel = info?.areaLabel;
    return TicketCard(
      showPerforation: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.auto_awesome_outlined, color: AppColors.ink),
            ],
          ),
          fieldGap,
          const WaveDivider(),
          if (timeLabel != null) ...[
            fieldGap,
            _InfoRow(
              key: const Key('keo_header_time'),
              icon: Icons.schedule_outlined,
              label: timeLabel,
            ),
          ],
          if (areaLabel != null && areaLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              key: const Key('keo_header_area'),
              icon: Icons.place_outlined,
              label: areaLabel,
            ),
          ],
          fieldGap,
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  border: Border.all(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: const Icon(Icons.groups_outlined, color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.keoDetailMemberCount(count) ??
                      '$count người trong kèo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.ink),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RosterTile extends StatelessWidget {
  const _RosterTile({
    super.key,
    required this.member,
    required this.statusText,
    required this.isHostViewer,
    required this.onApprove,
    required this.onDecline,
  });

  final KeoMember member;
  final String statusText;
  final bool isHostViewer;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final displayName =
        member.displayName ?? (l10n?.keoSharedAnonymous ?? 'Ẩn danh');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final isHost = member.role == 'host';
    final stampLabel = isHost
        ? (l10n?.keoDetailHostChip ?? 'Chủ kèo')
        : statusText;
    final stampTone = isHost || member.joinStatus == 'requested'
        ? StampChipTone.lime
        : StampChipTone.teal;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHost ? AppColors.secondary : AppColors.teal,
                  border: Border.all(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                  boxShadow: const [AppShadows.hard],
                ),
                child: Text(
                  initial,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.verified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: AppColors.ink,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      children: [
                        StampChip(
                          label: stampLabel,
                          tone: stampTone,
                          leadingIcon: isHost
                              ? Icons.auto_awesome_outlined
                              : member.joinStatus == 'requested'
                              ? Icons.schedule_outlined
                              : Icons.check_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isHostViewer && member.joinStatus == 'requested') ...[
            fieldGap,
            LayoutBuilder(
              builder: (context, constraints) {
                final stackActions =
                    constraints.maxWidth < 360 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final l10n = Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                );
                final approveLabel = l10n?.keoDetailApprove ?? 'Duyệt';
                final declineLabel = l10n?.keoDetailDecline ?? 'Từ chối';
                final approve = Tooltip(
                  message: approveLabel,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.ink,
                    ),
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(approveLabel),
                  ),
                );
                final decline = Tooltip(
                  message: declineLabel,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: onDecline,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(declineLabel),
                  ),
                );
                if (stackActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      approve,
                      const SizedBox(height: AppSpacing.xs),
                      decline,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: approve),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: decline),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.notMember,
    required this.isApproved,
    required this.isConfirmed,
    required this.isHost,
    required this.onRequestJoin,
    required this.onConfirm,
    required this.onOpenChat,
    required this.onPlan,
    required this.onLeave,
  });

  final bool notMember;
  final bool isApproved;
  final bool isConfirmed;
  final bool isHost;
  final VoidCallback onRequestJoin;
  final VoidCallback onConfirm;
  final VoidCallback onOpenChat;
  final VoidCallback onPlan;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notMember)
          GradientButton(
            key: const Key('request_join_btn'),
            onPressed: onRequestJoin,
            icon: Icons.login_rounded,
            child: Text(l10n?.keoDetailRequestJoin ?? 'Xin vào kèo'),
          ),
        if (isApproved && !isHost && !isConfirmed) ...[
          OutlinedButton.icon(
            key: const Key('confirm_keo_btn'),
            onPressed: onConfirm,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.ink,
            ),
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(l10n?.keoDetailConfirmJoin ?? 'Đồng ý tham gia'),
          ),
          fieldGap,
        ],
        if (isApproved && !isHost && isConfirmed) ...[
          OutlinedButton.icon(
            key: const Key('confirmed_state_btn'),
            onPressed: null,
            style: OutlinedButton.styleFrom(
              disabledBackgroundColor: AppColors.teal,
              disabledForegroundColor: AppColors.ink,
            ),
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n?.keoDetailConfirmed ?? 'Đã xác nhận tham gia'),
          ),
          fieldGap,
        ],
        if (isApproved) ...[
          GradientButton(
            key: const Key('open_keo_chat_btn'),
            onPressed: onOpenChat,
            icon: Icons.chat_bubble_outline_rounded,
            child: Text(l10n?.keoDetailOpenChat ?? 'Mở trò chuyện nhóm'),
          ),
          fieldGap,
        ],
        if (isHost)
          OutlinedButton.icon(
            key: const Key('host_pick_venue_btn'),
            onPressed: onPlan,
            icon: const Icon(Icons.place_outlined),
            label: Text(l10n?.keoDetailPickVenue ?? 'Chốt quán'),
          )
        else if (isApproved)
          OutlinedButton.icon(
            key: const Key('view_plan_btn'),
            onPressed: onPlan,
            icon: const Icon(Icons.map_outlined),
            label: Text(l10n?.keoDetailViewPlan ?? 'Xem kế hoạch'),
          ),
        if (isApproved && !isHost) ...[
          fieldGap,
          TextButton(
            onPressed: onLeave,
            child: Text(l10n?.keoDetailLeave ?? 'Rời kèo'),
          ),
        ],
      ],
    );
  }
}
