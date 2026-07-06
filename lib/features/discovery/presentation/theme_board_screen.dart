import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/discovery_providers.dart';
import '../domain/music_themes.dart';

/// Board mini-Khám Phá (Tinder-parity mục 9): lưới chủ đề nhạc, mỗi thẻ dẫn
/// tới một deck Đôi đã lọc theo genre đó (route /explore/:genre).
class ThemeBoardScreen extends ConsumerWidget {
  const ThemeBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(themeDeckCountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Khám Phá theo gu nhạc')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(AppSpacing.lg),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.95,
        children: [
          for (final theme in musicThemes)
            _ThemeCard(
              theme: theme,
              liveCount: counts.value?[theme.genreId],
              onTap: () => context.push('/explore/${theme.genreId}'),
            ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.liveCount,
    required this.onTap,
  });

  final MusicTheme theme;
  final int? liveCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('theme_card_${theme.genreId}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(theme.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              theme.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.onPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              theme.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                  ),
            ),
            const Spacer(),
            Text(
              liveCount == null ? '—' : '$liveCount người đang hát',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
