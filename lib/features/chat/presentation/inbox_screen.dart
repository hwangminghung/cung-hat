import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../keo/application/keo_providers.dart';
import '../../keo/domain/keo.dart';
import '../../profile/application/profile_providers.dart';
import '../application/inbox_providers.dart';
import '../data/match_inbox.dart';

/// Matches inbox hosted on the Chat tab.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key, this.onFindKeo});

  /// Switches the home shell to the Kèo tab (empty-state CTA).
  final VoidCallback? onFindKeo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inboxProvider);
    final myId = ref.watch(myProfileProvider).value?.id;
    // Section "Kèo của bạn" degrade êm: provider lỗi/đang tải → coi như rỗng,
    // không chặn inbox tin nhắn đôi.
    final keos = ref.watch(myKeosProvider).value ?? const <Keo>[];
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
          if (matches.isEmpty && keos.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_rounded,
              title: 'Chưa có cuộc trò chuyện nào',
              subtitle: 'Tìm kèo ngay để bắt đầu trò chuyện với những người bạn mới!',
              actionLabel: onFindKeo != null ? 'Tìm kèo ngay' : null,
              onAction: onFindKeo,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              const _InboxHeader(),
              if (keos.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.lg,
                    bottom: AppSpacing.sm,
                  ),
                  child: _SectionLabel('Kèo của bạn'),
                ),
                ..._withWaveDividers([
                  for (final keo in keos)
                    _KeoInboxTile(
                      key: ValueKey('my_keo_${keo.id}'),
                      keo: keo,
                      onTap: () async {
                        await context.push(
                          '/keo/${keo.id}?title=${Uri.encodeComponent(keo.title)}',
                        );
                        if (context.mounted) {
                          ref.invalidate(myKeosProvider);
                          ref.invalidate(inboxProvider);
                        }
                      },
                    ),
                ]),
              ],
              if (matches.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.lg,
                    bottom: AppSpacing.sm,
                  ),
                  child: _SectionLabel('Tin nhắn đôi'),
                ),
                ..._withWaveDividers([
                  for (final match in matches)
                    _buildMatchTile(context, ref, match, myId),
                ]),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatchTile(
    BuildContext context,
    WidgetRef ref,
    MatchSummary match,
    String? myId,
  ) {
    final otherName = match.otherName;
    final monogram =
        otherName.isEmpty ? '?' : otherName.characters.first.toUpperCase();
    String? turnLabel;
    if (match.lastSenderId == null) {
      turnLabel = 'Nhắn trước đi';
    } else if (myId != null && match.lastSenderId != myId) {
      turnLabel = 'Đến lượt bạn';
    }
    return _InboxTile(
      monogram: monogram,
      name: otherName,
      unread: match.unread,
      turnLabel: turnLabel,
      onTap: () async {
        await context.push(
          '/chat/${match.matchId}?name=${Uri.encodeComponent(otherName)}',
        );
        if (context.mounted) ref.invalidate(inboxProvider);
      },
    );
  }

  /// Chèn WaveDivider giữa các hàng (không chèn sau hàng cuối).
  static List<Widget> _withWaveDividers(List<Widget> tiles) {
    return [
      for (var i = 0; i < tiles.length; i++) ...[
        tiles[i],
        if (i < tiles.length - 1)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: WaveDivider(),
          ),
      ],
    ];
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

/// Hàng kèo trong section "Kèo của bạn" (mockup 15): ô vé teal + tên kèo +
/// trạng thái, chip x/y bên phải, thêm "Chủ kèo" khi mình là host.
class _KeoInboxTile extends StatelessWidget {
  const _KeoInboxTile({super.key, required this.keo, required this.onTap});

  final Keo keo;
  final VoidCallback onTap;

  static String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Đang mở';
      case 'full':
        return 'Đủ người';
      case 'planning':
        return 'Đang lên kế hoạch';
      case 'confirmed':
        return 'Đã chốt';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final area = keo.areaLabel;
    final subtitle = area == null || area.isEmpty
        ? _statusLabel(keo.status)
        : '${_statusLabel(keo.status)} · $area';
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
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.ink,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (keo.isMine) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: StampChip(
                          label: 'Chủ kèo',
                          tone: StampChipTone.lime,
                          leadingIcon: Icons.auto_awesome_outlined,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                key: const Key('my_keo_count'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.ink, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${keo.slotsFilled}/${keo.sizeTarget}',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
