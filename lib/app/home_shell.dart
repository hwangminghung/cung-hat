import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../l10n/app_localizations.dart';
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
import '../shared/widgets/tab_header.dart';
import '../shared/widgets/wave_divider.dart';
import '../shared/widgets/wave_progress.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  /// [AUDIT M7] Tab đã thăm được giữ sống trong IndexedStack (giữ scroll/
  /// deck state khi chuyển tab); tab CHƯA thăm là SizedBox để giữ lazy-init
  /// như switch cũ — không fetch inbox/kèo trước khi user vào tab
  /// (home_shell_test khẳng định inboxCalls == 0 trước lần thăm đầu).
  final Set<int> _visited = {0};

  // Icon set follows design-system/MASTER.md: Đôi group · Kèo mic ·
  // Chat chat_bubble · Hồ sơ person.
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

  void _select(int i) {
    // inboxProvider là FutureProvider one-shot: không refetch khi vào
    // tab Chat thì pill 'Đến lượt bạn'/badge unread trễ tới khi user mở
    // 1 chat hoặc restart. Invalidate mỗi lần CHỌN tab 2 (NavigationBar
    // fire cả khi re-tap tab hiện tại — refetch thừa vô hại, coi như
    // pull-to-refresh). Realtime subscription: ngoài scope, không làm.
    if (i == 2) ref.invalidate(inboxProvider);
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final labels = [
      l10n?.tabDoi ?? 'Đôi',
      l10n?.tabKeo ?? 'Kèo',
      l10n?.tabChat ?? 'Tin nhắn',
      l10n?.tabProfile ?? 'Hồ sơ',
    ];
    final tabs = <Widget Function()>[
      () => const DoiDeckScreen(),
      () => const KeoBoardScreen(),
      () => InboxScreen(onFindKeo: () => _select(1)),
      () => const _ProfileTab(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _visited.contains(i) ? tabs[i]() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_iconsSel[i]),
              label: labels[i],
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final profile = ref.watch(myProfileProvider).value;
    final name = profile?.displayName?.trim();
    // UI review: header theo quy tắc chung 4 tab; bỏ nút bánh răng trùng lặp
    // — Cài đặt vẫn còn nguyên qua card cuối danh sách (không mất chức năng,
    // hết cảm giác hai lối vào cùng một màn hình).
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabHeader(title: l10n?.tabProfile ?? 'Hồ sơ'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
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
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (name?.isNotEmpty ?? false)
                                ? name!
                                : (l10n?.tabProfile ?? 'Hồ sơ'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: AppColors.ink),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            (profile?.bio?.trim().isNotEmpty ?? false)
                                ? profile!.bio!.trim()
                                : (l10n?.shellProfileSub ??
                                      'Quản lý lượt thích, gói nâng cấp và cài đặt.'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
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
                  title: l10n?.shellTileLikes ?? 'Ai đã thích bạn',
                  badgeLabel: 'PRO',
                  subtitle:
                      l10n?.shellTileLikesSub ??
                      'Mở danh sách người đã thả tim',
                  onTap: () {
                    final unlocked = ref.read(
                      hasEntitlementProvider('see_likes'),
                    );
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
                  title: l10n?.storeTitle ?? 'Nâng cấp',
                  subtitle:
                      l10n?.shellTileUpgradeSub ??
                      'Pro, boost kèo và bộ lọc nâng cao',
                  onTap: () => context.push('/store'),
                ),
                _ProfileTile(
                  icon: Icons.photo_library_rounded,
                  title: l10n?.shellTilePhotos ?? 'Ảnh hồ sơ',
                  subtitle:
                      l10n?.shellTilePhotosSub ?? 'Thêm tối đa 6 ảnh vào hồ sơ',
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
                  title: l10n?.shellTilePrompts ?? 'Thẻ hỏi-đáp',
                  subtitle:
                      l10n?.shellTilePromptsSub ??
                      'Chọn tối đa 3 câu để hồ sơ có chuyện mà bắt',
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
                  title: l10n?.settingsTitle ?? 'Cài đặt',
                  subtitle:
                      l10n?.shellTileSettingsSub ??
                      'Quyền riêng tư, dữ liệu và pháp lý',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final profile = ref.watch(myProfileProvider).value;
    final taste = ref.watch(myTasteCountsProvider).value;
    if (profile == null || taste == null) return const SizedBox.shrink();
    final r = profileCompletion(profile, taste, l10n: l10n);
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
            l10n?.completionPercent(r.percent) ??
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
          // UI review: mô tả tối đa 2 dòng cho mọi card, không đẩy lệch hàng.
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
