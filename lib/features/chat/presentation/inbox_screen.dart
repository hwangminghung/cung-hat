import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../profile/application/profile_providers.dart';
import '../application/inbox_providers.dart';

/// Matches inbox hosted on the Chat tab.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key, this.onFindKeo});

  /// Switches the home shell to the Kèo tab (empty-state CTA).
  final VoidCallback? onFindKeo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inboxProvider);
    final myId = ref.watch(myProfileProvider).value?.id;
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
              if (index == 0) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InboxHeader(),
                    Padding(
                      padding: EdgeInsets.only(
                        top: AppSpacing.lg,
                        bottom: AppSpacing.sm,
                      ),
                      child: _SectionLabel('Tin nhắn đôi'),
                    ),
                  ],
                );
              }
              final match = matches[index - 1];
              final monogram = match.otherName.isEmpty
                  ? '?'
                  : match.otherName.characters.first.toUpperCase();
              String? turnLabel;
              if (match.lastSenderId == null) {
                turnLabel = 'Nhắn trước đi';
              } else if (myId != null && match.lastSenderId != myId) {
                turnLabel = 'Đến lượt bạn';
              }
              final tile = _InboxTile(
                monogram: monogram,
                name: match.otherName,
                unread: match.unread,
                turnLabel: turnLabel,
                onTap: () async {
                  await context.push(
                    '/chat/${match.matchId}?name=${Uri.encodeComponent(match.otherName)}',
                  );
                  if (context.mounted) ref.invalidate(inboxProvider);
                },
              );
              final isLast = index == matches.length;
              if (isLast) return tile;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tile,
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: WaveDivider(),
                  ),
                ],
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
    this.turnLabel,
  });

  final String monogram;
  final String name;
  final int unread;
  final VoidCallback onTap;
  final String? turnLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Text(
                  monogram,
                  style: textTheme.titleLarge?.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (turnLabel != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          key: const Key('turn_pill'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            border: Border.all(
                              color: AppColors.ink,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            turnLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        'Sẵn sàng rủ đi hát',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                _UnreadBadge(count: unread),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
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
