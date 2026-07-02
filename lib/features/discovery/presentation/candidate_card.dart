import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/candidate.dart';
import 'report_sheet.dart';

class CandidateCard extends StatelessWidget {
  const CandidateCard({super.key, required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final name = candidate.displayName ?? 'Bạn hát mới';
    final monogram = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final title = candidate.age == null ? name : '$name, ${candidate.age}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.brandGradient),
                ),
                Positioned(
                  left: -36,
                  top: 34,
                  child: Transform.rotate(
                    angle: -0.32,
                    child: Container(
                      width: 180,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -18,
                  bottom: 54,
                  child: Transform.rotate(
                    angle: 0.28,
                    child: Container(
                      width: 142,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryTint.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    monogram,
                    style: AppTypography.display(
                      fontSize: 104,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onPrimary.withValues(alpha: 0.92),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: IconButton.filledTonal(
                    tooltip: 'Báo cáo',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => ReportSheet(targetId: candidate.id),
                    ),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ),
                if (candidate.activeToday)
                  const Positioned(
                    left: AppSpacing.lg,
                    top: AppSpacing.lg,
                    child: _Badge(
                      icon: Icons.bolt_rounded,
                      label: 'Online hôm nay',
                      background: AppColors.secondary,
                      foreground: AppColors.secondaryDark,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (candidate.verified)
                      const Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: AppColors.tertiary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Badge(
                      icon: Icons.place_rounded,
                      label: 'Cách ${candidate.distanceBand ?? '?'} km',
                      background: AppColors.primaryTint,
                      foreground: AppColors.primaryDark,
                    ),
                    _Badge(
                      icon: Icons.music_note_rounded,
                      label: 'cùng ${candidate.sharedBaitu.length} bài tủ',
                      background: AppColors.tertiaryTint,
                      foreground: AppColors.tertiary,
                    ),
                  ],
                ),
                if (candidate.sharedGenres.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final genre in candidate.sharedGenres.take(3))
                        _GenreChip(label: genre),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '#$label',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
