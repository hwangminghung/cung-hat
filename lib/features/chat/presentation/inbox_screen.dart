import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hard_card.dart';
import '../../../shared/widgets/responsive_frame.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/tab_header.dart';
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final async = ref.watch(inboxProvider);
    // Section "Kèo của bạn" degrade êm: provider lỗi/đang tải → coi như rỗng,
    // không chặn inbox tin nhắn đôi.
    final keos = ref.watch(myKeosProvider).value ?? const <Keo>[];
    // UI review: header "Tin nhắn" LUÔN hiện (cả loading/lỗi/rỗng) theo quy
    // tắc chung 4 tab — trước đây màn rỗng bắt đầu bằng khoảng trắng lớn.
    return ResponsiveFrame(
      child: KeyedSubtree(
        key: const Key('screen_15_inbox'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabHeader(
              title: l10n?.inboxTitle ?? 'Tin nhắn',
              subtitle:
                  l10n?.inboxSubtitle ??
                  'Nơi giữ các cuộc trò chuyện sau khi chung gu.',
            ),
            Expanded(child: _buildBody(context, ref, l10n, async, keos)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
    AsyncValue<List<MatchSummary>> async,
    List<Keo> keos,
  ) {
    final myId = ref.watch(myProfileProvider).value?.id;
    return async.when(
      loading: () => ListView(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        children: const [SkeletonTile(), SkeletonTile(), SkeletonTile()],
      ),
      error: (e, _) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: l10n?.inboxLoadError ?? 'Không tải được cuộc trò chuyện',
        subtitle:
            l10n?.commonCheckConnection ?? 'Kiểm tra kết nối rồi thử lại.',
        actionLabel: l10n?.commonRetry ?? 'Thử lại',
        onAction: () => ref.invalidate(inboxProvider),
      ),
      data: (matches) {
        if (matches.isEmpty && keos.isEmpty) {
          return EmptyState(
            icon: Icons.chat_bubble_rounded,
            title: l10n?.inboxEmptyTitle ?? 'Chưa có cuộc trò chuyện',
            subtitle:
                l10n?.inboxEmptySub ??
                'Tham gia một kèo để bắt đầu trò chuyện với những người bạn mới.',
            actionLabel: onFindKeo != null
                ? (l10n?.inboxFindKeo ?? 'Tìm kèo')
                : null,
            onAction: onFindKeo,
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            if (keos.isNotEmpty) ...[
              _InboxSection(
                key: const Key('inbox_keo_section'),
                title: l10n?.inboxSectionKeo ?? 'Kèo của bạn',
                children: [
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
                ],
              ),
            ],
            if (keos.isNotEmpty && matches.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: WaveDivider(),
              ),
            if (matches.isNotEmpty)
              _InboxSection(
                key: const Key('inbox_match_section'),
                title: l10n?.inboxSectionMatches ?? 'Tin nhắn đôi',
                children: [
                  for (final match in matches)
                    _buildMatchTile(context, ref, match, myId),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildMatchTile(
    BuildContext context,
    WidgetRef ref,
    MatchSummary match,
    String? myId,
  ) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final otherName = match.otherName;
    final monogram = otherName.isEmpty
        ? '?'
        : otherName.characters.first.toUpperCase();
    String? turnLabel;
    if (match.lastSenderId == null) {
      turnLabel = l10n?.inboxTurnFirst ?? 'Nhắn trước đi';
    } else if (myId != null && match.lastSenderId != myId) {
      turnLabel = l10n?.inboxTurnYours ?? 'Đến lượt bạn';
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
}

class _InboxSection extends StatelessWidget {
  const _InboxSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
          child: _SectionLabel(title),
        ),
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
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
    return HardCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                        Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            )?.inboxReady ??
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

  static String _statusLabel(String status, AppLocalizations? l10n) {
    switch (status) {
      case 'open':
        return l10n?.keoStateOpen ?? 'Đang mở';
      case 'full':
        return l10n?.keoStateFull ?? 'Đủ người';
      case 'planning':
        return l10n?.keoStatePlanning ?? 'Đang lên kế hoạch';
      case 'confirmed':
        return l10n?.keoStateConfirmed ?? 'Đã chốt';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final textTheme = Theme.of(context).textTheme;
    final area = keo.areaLabel;
    final subtitle = area == null || area.isEmpty
        ? _statusLabel(keo.status, l10n)
        : '${_statusLabel(keo.status, l10n)} · $area';
    final ticket = Container(
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
    );
    final count = Container(
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
    );

    Widget details({required bool countBesideTitle}) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (countBesideTitle)
          Row(
            children: [
              Expanded(
                child: Text(
                  keo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              count,
            ],
          )
        else
          Text(
            keo.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(color: AppColors.ink),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        if (keo.isMine) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: StampChip(
              label: l10n?.keoDetailHostChip ?? 'Chủ kèo',
              tone: StampChipTone.lime,
              leadingIcon: Icons.auto_awesome_outlined,
            ),
          ),
        ],
      ],
    );
    return HardCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useCompactLayout =
                  constraints.maxWidth < 320 &&
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ticket,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: details(countBesideTitle: useCompactLayout)),
                  if (!useCompactLayout) ...[
                    const SizedBox(width: AppSpacing.sm),
                    count,
                  ],
                ],
              );
            },
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
