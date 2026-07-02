import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/inbox_providers.dart';

/// Matches inbox hosted on the Chat tab.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key, this.onFindKeo});

  /// Switches the home shell to the Kèo tab (empty-state CTA).
  final VoidCallback? onFindKeo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inboxProvider);
    return SafeArea(
      child: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          children: const [SkeletonTile(), SkeletonTile(), SkeletonTile()],
        ),
        error: (e, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Không tải được cuộc trò chuyện',
          subtitle: 'Kiểm tra kết nối rồi thử lại.',
          actionLabel: 'Thử lại',
          onAction: () => ref.invalidate(inboxProvider),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_rounded,
              title: 'Chưa có cuộc trò chuyện nào',
              subtitle: 'Tìm kèo ngay để bắt đầu trò chuyện với những người bạn mới!',
              actionLabel: onFindKeo != null ? 'Tìm kèo ngay' : null,
              onAction: onFindKeo,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            itemCount: matches.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return const _InboxHeader();
              final match = matches[index - 1];
              final monogram = match.otherName.isEmpty
                  ? '?'
                  : match.otherName.characters.first.toUpperCase();
              return _InboxTile(
                monogram: monogram,
                name: match.otherName,
                unread: match.unread,
                onTap: () async {
                  await context.push(
                    '/chat/${match.matchId}?name=${Uri.encodeComponent(match.otherName)}',
                  );
                  if (context.mounted) ref.invalidate(inboxProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tin nhắn', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nơi giữ các cuộc trò chuyện sau khi chung gu.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.monogram,
    required this.name,
    required this.unread,
    required this.onTap,
  });

  final String monogram;
  final String name;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            monogram,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.onPrimary),
          ),
        ),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: const Text('Sẵn sàng rủ đi hát'),
        trailing: unread > 0
            ? _UnreadBadge(count: unread)
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
