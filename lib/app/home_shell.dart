import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../features/billing/application/billing_providers.dart';
import '../features/chat/application/inbox_providers.dart';
import '../features/chat/presentation/inbox_screen.dart';
import '../features/discovery/presentation/doi_deck_screen.dart';
import '../features/keo/presentation/keo_board_screen.dart';
import '../features/photos/presentation/photo_manager_sheet.dart';
import '../features/profile/application/profile_providers.dart';
import '../features/profile/domain/profile_completion.dart';
import '../features/profile/presentation/prompt_editor_sheet.dart';
import '../shared/widgets/stamp_chip.dart';
import '../shared/widgets/wave_divider.dart';
import '../shared/widgets/wave_progress.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  // Icon set follows design-system/MASTER.md: Đôi group · Kèo mic ·
  // Chat chat_bubble · Hồ sơ person.
  static const _labels = ['Đôi', 'Kèo', 'Chat', 'Hồ sơ'];
  static const _icons = [
    Icons.group_outlined,
    Icons.mic_external_on_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];
  static const _iconsSel = [
    Icons.group_rounded,
    Icons.mic_external_on_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_index) {
        0 => const DoiDeckScreen(),
        1 => const KeoBoardScreen(),
        2 => InboxScreen(onFindKeo: () => setState(() => _index = 1)),
        3 => const _ProfileTab(),
        _ => Center(child: Text(_labels[_index])),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          // inboxProvider là FutureProvider one-shot: không refetch khi vào
          // tab Chat thì pill 'Đến lượt bạn'/badge unread trễ tới khi user mở
          // 1 chat hoặc restart. Invalidate mỗi lần CHỌN tab 2 (NavigationBar
          // fire cả khi re-tap tab hiện tại — refetch thừa vô hại, coi như
          // pull-to-refresh). Realtime subscription: ngoài scope, không làm.
          if (i == 2) ref.invalidate(inboxProvider);
          setState(() => _index = i);
        },
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_iconsSel[i]),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  String _monogram(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final name = profile?.displayName?.trim();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Row(
            children: [
              Text('Hồ sơ', style: Theme.of(context).textTheme.displaySmall),
              const Spacer(),
              IconButton.outlined(
                key: const Key('profile_gear_btn'),
                tooltip: 'Cài đặt',
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  border: Border.all(color: AppColors.border, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [AppShadows.hard],
                ),
                child: Text(
                  _monogram(name),
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (name?.isNotEmpty ?? false) ? name! : 'Hồ sơ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      (profile?.bio?.trim().isNotEmpty ?? false)
                          ? profile!.bio!.trim()
                          : 'Quản lý lượt thích, gói nâng cấp và cài đặt.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const WaveDivider(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _CompletionCard(),
          const SizedBox(height: AppSpacing.md),
          _ProfileTile(
            icon: Icons.favorite_rounded,
            title: 'Ai đã thích bạn',
            badgeLabel: 'PRO',
            subtitle: 'Mở danh sách người đã thả tim',
            onTap: () {
              final unlocked = ref.read(hasEntitlementProvider('see_likes'));
              if (unlocked) {
                context.push('/likes');
              } else {
                // Free: màn teaser mosaic thay vì bung sheet Pro ngay — sheet
                // giờ nằm sau CTA trong màn teaser (likes_teaser_screen.dart).
                context.push('/likes-teaser');
              }
            },
          ),
          _ProfileTile(
            icon: Icons.workspace_premium_rounded,
            title: 'Nâng cấp',
            subtitle: 'Pro, boost kèo và bộ lọc nâng cao',
            onTap: () => context.push('/store'),
          ),
          _ProfileTile(
            icon: Icons.photo_library_rounded,
            title: 'Ảnh hồ sơ',
            subtitle: 'Thêm tối đa 6 ảnh vào hồ sơ',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: false,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusSheet),
                ),
              ),
              builder: (_) => const PhotoManagerSheet(),
            ),
          ),
          _ProfileTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Thẻ hỏi-đáp',
            subtitle: 'Chọn tối đa 3 câu để hồ sơ có chuyện mà bắt',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: false,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusSheet),
                ),
              ),
              builder: (_) => const PromptEditorSheet(),
            ),
          ),
          _ProfileTile(
            icon: Icons.settings_rounded,
            title: 'Cài đặt',
            subtitle: 'Quyền riêng tư, dữ liệu và pháp lý',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends ConsumerWidget {
  const _CompletionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final taste = ref.watch(myTasteCountsProvider).value;
    if (profile == null || taste == null) return const SizedBox.shrink();
    final r = profileCompletion(profile, taste);
    if (r.percent >= 100) return const SizedBox.shrink();
    return Container(
      key: const Key('completion_card'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hồ sơ hoàn thiện ${r.percent}%',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          WaveProgress(progress: r.percent / 100),
          for (final step in r.nextSteps)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_circle_up_rounded,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      // Mirror _InboxTile (inbox_screen.dart): không borderRadius +
      // clipBehavior thì ink splash tràn ra ngoài góc bo của card.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.ink, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.ink),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeLabel != null) ...[
                const SizedBox(width: AppSpacing.sm),
                StampChip(label: badgeLabel!),
              ],
            ],
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
