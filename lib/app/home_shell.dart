import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../features/billing/application/billing_providers.dart';
import '../features/chat/presentation/inbox_screen.dart';
import '../features/discovery/presentation/doi_deck_screen.dart';
import '../features/keo/presentation/keo_board_screen.dart';
import '../features/photos/presentation/photo_manager_sheet.dart';
import '../features/profile/application/profile_providers.dart';
import '../shared/widgets/pro_upsell_sheet.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
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
        onDestinationSelected: (i) => setState(() => _index = i),
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
          Container(
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
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _monogram(name),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: AppColors.onPrimary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (name?.isNotEmpty ?? false) ? name! : 'Hồ sơ',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: AppColors.onPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        (profile?.bio?.trim().isNotEmpty ?? false)
                            ? profile!.bio!.trim()
                            : 'Quản lý lượt thích, gói nâng cấp và cài đặt.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileTile(
            icon: Icons.favorite_rounded,
            title: 'Ai đã thích bạn',
            subtitle: 'Mở danh sách người đã thả tim',
            onTap: () {
              final unlocked = ref.read(hasEntitlementProvider('see_likes'));
              if (unlocked) {
                context.push('/likes');
              } else {
                ProUpsellSheet.show(context, variant: ProUpsellVariant.seeLikes);
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
            subtitle: 'Thêm tối đa 3 ảnh vào hồ sơ',
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
