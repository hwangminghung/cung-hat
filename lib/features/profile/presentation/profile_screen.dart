import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/hard_card.dart';
import '../../../shared/widgets/responsive_frame.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/tab_header.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../../shared/widgets/wave_progress.dart';
import '../../billing/application/billing_providers.dart';
import '../../photos/presentation/photo_manager_sheet.dart';
import '../application/profile_providers.dart';
import '../domain/profile.dart';
import '../domain/profile_completion.dart';
import 'prompt_editor_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return ResponsiveFrame(
      child: KeyedSubtree(
        key: const Key('screen_18_profile'),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              TabHeader(title: l10n?.tabProfile ?? 'Hồ sơ'),
              const Expanded(child: _ProfileContent()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final taste = ref.watch(myTasteCountsProvider).value;
    return _ProfileList(profile: profile, taste: taste);
  }
}

class _ProfileList extends ConsumerWidget {
  const _ProfileList({required this.profile, required this.taste});

  final Profile? profile;
  final TasteCounts? taste;

  String _monogram(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final name = profile?.displayName?.trim();
    final displayName = (name?.isNotEmpty ?? false)
        ? name!
        : (l10n?.tabProfile ?? 'Hồ sơ');
    final bio = (profile?.bio?.trim().isNotEmpty ?? false)
        ? profile!.bio!.trim()
        : (l10n?.shellProfileSub ??
              'Quản lý lượt thích, gói nâng cấp và cài đặt.');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        HardCard(
          key: const Key('profile_identity_card'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    border: Border.all(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    boxShadow: const [AppShadows.hard],
                  ),
                  child: Text(
                    _monogram(name),
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        bio,
                        maxLines: 3,
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
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _CompletionCard(profile: profile, taste: taste),
        if (profile != null && taste != null) ...[
          const SizedBox(height: AppSpacing.lg),
        ],
        _ProfileTile(
          icon: Icons.favorite_rounded,
          title: l10n?.shellTileLikes ?? 'Ai đã thích bạn',
          badgeLabel: 'PRO',
          subtitle: l10n?.shellTileLikesSub ?? 'Mở danh sách người đã thả tim',
          onTap: () {
            final unlocked = ref.read(hasEntitlementProvider('see_likes'));
            context.push(unlocked ? '/likes' : '/likes-teaser');
          },
        ),
        _ProfileTile(
          icon: Icons.workspace_premium_rounded,
          title: l10n?.storeTitle ?? 'Nâng cấp',
          subtitle:
              l10n?.shellTileUpgradeSub ??
              'Pro, tăng hiển thị kèo và bộ lọc nâng cao',
          onTap: () => context.push('/store'),
        ),
        _ProfileTile(
          icon: Icons.photo_library_rounded,
          title: l10n?.shellTilePhotos ?? 'Ảnh hồ sơ',
          subtitle: l10n?.shellTilePhotosSub ?? 'Thêm tối đa 6 ảnh vào hồ sơ',
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
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.profile, required this.taste});

  final Profile? profile;
  final TasteCounts? taste;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    final taste = this.taste;
    if (profile == null || taste == null) return const SizedBox.shrink();

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final result = profileCompletion(profile, taste, l10n: l10n);
    if (result.percent >= 100) return const SizedBox.shrink();

    return HardCard(
      key: const Key('completion_card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.completionPercent(result.percent) ??
                  'Hồ sơ hoàn thiện ${result.percent}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            WaveProgress(progress: result.percent / 100),
            for (final step in result.nextSteps)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.arrow_circle_up_rounded,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
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
    return HardCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
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
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (badgeLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              StampChip(label: badgeLabel!),
            ],
          ],
        ),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
