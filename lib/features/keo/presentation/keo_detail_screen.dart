import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pro_upsell_sheet.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../profile/application/profile_providers.dart';
import '../application/keo_providers.dart';
import '../data/keo_errors.dart';
import '../domain/keo_member.dart';

class KeoDetailScreen extends ConsumerWidget {
  const KeoDetailScreen({super.key, required this.keoId, required this.title});

  final String keoId;
  final String title;

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Đã duyệt';
      case 'requested':
        return 'Chờ duyệt';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'left':
        return 'Đã rời';
      case 'declined':
        return 'Bị từ chối';
      default:
        return status;
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(keoRosterProvider(keoId));
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết kèo')),
      body: rosterAsync.when(
        data: (roster) => _buildBody(context, ref, roster),
        loading: () => ListView(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          children: const [SkeletonTile(), SkeletonTile(), SkeletonTile()],
        ),
        error: (e, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Không tải được kèo',
          subtitle: 'Kiểm tra kết nối rồi thử lại.',
          actionLabel: 'Thử lại',
          onAction: () => ref.invalidate(keoRosterProvider(keoId)),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<KeoMember> roster,
  ) {
    final uid = ref.watch(myProfileProvider).value?.id;
    KeoMember? myRow;
    for (final member in roster) {
      if (member.userId == uid) {
        myRow = member;
        break;
      }
    }
    final isHost = myRow?.role == 'host';
    final isApproved = myRow?.joinStatus == 'approved';
    final notMember = myRow == null || myRow.joinStatus == 'left';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        _Header(title: title, count: roster.length),
        const SizedBox(height: AppSpacing.lg),
        Text('Thành viên', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final member in roster)
          _RosterTile(
            key: ValueKey(member.userId),
            member: member,
            statusText: _statusText(member.joinStatus),
            isHostViewer: isHost,
            onApprove: () => _approve(context, ref, member),
            onDecline: () => _decline(context, ref, member),
          ),
        const SizedBox(height: AppSpacing.xl),
        _ActionPanel(
          notMember: notMember,
          isApproved: isApproved,
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
      if (context.mounted) _snack(context, 'Không duyệt được');
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
      if (context.mounted) _snack(context, 'Không từ chối được');
    }
  }

  Future<void> _requestJoin(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(keoRepositoryProvider).requestJoin(keoId);
      ref.invalidate(keoRosterProvider(keoId));
    } catch (e) {
      if (!context.mounted) return;
      if (keoErrorCode(e) == 'free_join_limit') {
        ProUpsellSheet.show(context, variant: ProUpsellVariant.keoJoinLimit);
      } else {
        _snack(context, keoErrorMessage(e));
      }
    }
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(keoRepositoryProvider).confirm(keoId);
      ref.invalidate(keoRosterProvider(keoId));
    } catch (_) {
      if (context.mounted) _snack(context, 'Không xác nhận được');
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(keoRepositoryProvider).leave(keoId);
      ref.invalidate(keoRosterProvider(keoId));
    } catch (_) {
      if (context.mounted) _snack(context, 'Không rời kèo được');
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: AppColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$count người trong kèo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final displayName = member.displayName ?? 'Ẩn danh';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: member.role == 'host'
                  ? AppColors.primaryTint
                  : AppColors.tertiaryTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              initial,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: member.role == 'host'
                    ? AppColors.primaryDark
                    : AppColors.tertiary,
              ),
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
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.verified) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.tertiary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  member.role == 'host' ? 'Chủ kèo' : statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isHostViewer && member.joinStatus == 'requested')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Duyệt',
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded),
                ),
                IconButton(
                  tooltip: 'Từ chối',
                  onPressed: onDecline,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.notMember,
    required this.isApproved,
    required this.isHost,
    required this.onRequestJoin,
    required this.onConfirm,
    required this.onOpenChat,
    required this.onPlan,
    required this.onLeave,
  });

  final bool notMember;
  final bool isApproved;
  final bool isHost;
  final VoidCallback onRequestJoin;
  final VoidCallback onConfirm;
  final VoidCallback onOpenChat;
  final VoidCallback onPlan;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notMember)
          FilledButton.icon(
            key: const Key('request_join_btn'),
            onPressed: onRequestJoin,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Xin vào kèo'),
          ),
        if (isApproved && !isHost)
          FilledButton.icon(
            key: const Key('confirm_keo_btn'),
            onPressed: onConfirm,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Đồng ý tham gia'),
          ),
        if (isApproved) ...[
          OutlinedButton.icon(
            key: const Key('open_keo_chat_btn'),
            onPressed: onOpenChat,
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text('Mở chat nhóm'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (isHost)
          OutlinedButton.icon(
            key: const Key('host_pick_venue_btn'),
            onPressed: onPlan,
            icon: const Icon(Icons.place_rounded),
            label: const Text('Chốt quán'),
          )
        else if (isApproved)
          OutlinedButton.icon(
            key: const Key('view_plan_btn'),
            onPressed: onPlan,
            icon: const Icon(Icons.map_rounded),
            label: const Text('Xem kế hoạch'),
          ),
        if (isApproved && !isHost) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onLeave, child: const Text('Rời kèo')),
        ],
      ],
    );
  }
}
