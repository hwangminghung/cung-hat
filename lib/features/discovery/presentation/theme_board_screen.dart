import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_frame.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../application/discovery_providers.dart';
import '../domain/music_themes.dart';

/// Board mini-Khám Phá (Tinder-parity mục 9): lưới chủ đề nhạc, mỗi thẻ dẫn
/// tới một deck Đôi đã lọc theo genre đó (route /explore/:genre).
class ThemeBoardScreen extends ConsumerWidget {
  const ThemeBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(themeDeckCountsProvider);
    // [AUDIT theme-counts] Truoc day truyen thang counts.value: AsyncLoading
    // va AsyncError deu cho null nen ca hai deu hien '—' — loi mang bi nuot,
    // nhin y het luc dang tai. Tach hai trang thai bang .when().
    final (countsData, countsLoading) = counts.when<(Map<String, int>?, bool)>(
      loading: () => (null, true),
      error: (_, _) => (null, false),
      data: (value) => (value, false),
    );
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final indexedThemes = musicThemes.indexed.toList(growable: false);
    final canPop = Navigator.of(context).canPop();
    final duration = MediaQuery.maybeDisableAnimationsOf(context) == true
        ? Duration.zero
        : AppMotion.slow;

    return Scaffold(
      body: ResponsiveFrame(
        key: const Key('screen_10_explore_themes'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canPop)
                    _RetroBackButton(onTap: () => context.pop())
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  const SizedBox(width: 144, child: WaveDivider()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n?.discoveryExploreTitle ?? 'Khám phá theo gu nhạc',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.ink,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 0.98,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n?.discoveryExploreSubtitle ??
                    'Chọn một chất nhạc, gặp người cùng tần số.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ThemeColumn(
                      entries: indexedThemes
                          .where((entry) => entry.$1.isEven)
                          .toList(growable: false),
                      counts: countsData,
                      loading: countsLoading,
                      entranceDuration: duration,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: _ThemeColumn(
                        entries: indexedThemes
                            .where((entry) => entry.$1.isOdd)
                            .toList(growable: false),
                        counts: countsData,
                        loading: countsLoading,
                        entranceDuration: duration,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 328),
                  child: Container(
                    key: const Key('theme_brand_plaque'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.ink, width: 2),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusCard,
                      ),
                      boxShadow: const [AppShadows.hard],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.graphic_eq_rounded),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n?.discoveryExploreBrand ?? 'CÙNG HÁT',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.graphic_eq_rounded),
                      ],
                    ),
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

class _ThemeColumn extends StatelessWidget {
  const _ThemeColumn({
    required this.entries,
    required this.counts,
    required this.loading,
    required this.entranceDuration,
  });

  final List<(int, MusicTheme)> entries;
  final Map<String, int>? counts;

  /// Dang cho get_theme_deck_counts — hien Skeleton thay cho so lieu.
  final bool loading;
  final Duration entranceDuration;

  @override
  Widget build(BuildContext context) {
    const heights = [256.0, 240.0, 244.0, 264.0, 252.0];
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final scaledHeightAllowance = textScale > 1 ? (textScale - 1) * 140 : 0.0;
    return Column(
      children: [
        for (final entry in entries) ...[
          TweenAnimationBuilder<double>(
            duration: entranceDuration,
            curve: AppMotion.enterCurve,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: child,
              ),
            ),
            child: SizedBox(
              height: heights[entry.$1] + scaledHeightAllowance,
              child: _ThemeCard(
                theme: entry.$2,
                liveCount: counts?[entry.$2.genreId],
                loading: loading,
                onTap: () => context.push('/explore/${entry.$2.genreId}'),
              ),
            ),
          ),
          if (entry != entries.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.liveCount,
    required this.loading,
    required this.onTap,
  });

  final MusicTheme theme;
  final int? liveCount;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    // [AUDIT theme-counts] '—' gio CHI con danh cho loi / thieu du lieu;
    // trang thai dang tai da co Skeleton rieng ben duoi.
    final status = liveCount == null
        ? '—'
        : theme.genreId == 'bolero' && liveCount == 0
        ? l10n?.discoveryExploreOpen ?? 'Đang mở'
        : l10n?.discoveryExploreLiveCount(liveCount!) ??
              '$liveCount người đang hát';

    return Semantics(
      button: true,
      label: l10n?.exploreOpenSemantics(theme.title) ?? 'Mở ${theme.title}',
      child: Pressable(
        key: Key('theme_card_${theme.genreId}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.ink, width: 2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            boxShadow: const [AppShadows.hard],
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      theme.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.onPrimary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                theme.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const WaveDivider(height: AppSpacing.lg),
              if (loading)
                const Skeleton(width: 120, height: 28, radius: AppSpacing.xs)
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: StampChip(
                    leadingIcon: Icons.group_outlined,
                    label: status,
                    tone: StampChipTone.lime,
                  ),
                ),
              const Spacer(),
              _ThemeIllustration(genreId: theme.genreId, emoji: theme.emoji),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeIllustration extends StatelessWidget {
  const _ThemeIllustration({required this.genreId, required this.emoji});

  final String genreId;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final icon = switch (genreId) {
      'ballad' => Icons.nights_stay_outlined,
      'rap_vn' => Icons.mic_external_on_outlined,
      'bolero' => Icons.music_note_rounded,
      'kpop' => Icons.star_outline_rounded,
      _ => Icons.album_outlined,
    };

    return SizedBox(
      height: 58,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Icon(icon, size: 42, color: AppColors.ink),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(emoji, style: const TextStyle(fontSize: 44)),
          ),
        ],
      ),
    );
  }
}

class _RetroBackButton extends StatelessWidget {
  const _RetroBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Semantics(
      button: true,
      label: l10n?.commonBack ?? 'Quay lại',
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.ink, width: 2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            boxShadow: const [AppShadows.hard],
          ),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
        ),
      ),
    );
  }
}
