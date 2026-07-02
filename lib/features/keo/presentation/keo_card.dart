import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/pressable.dart';
import '../domain/keo.dart';

class KeoCard extends StatelessWidget {
  const KeoCard({super.key, required this.keo, this.onTap});

  final Keo keo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final place =
        keo.areaLabel ??
        (keo.distanceBand == null ? null : 'cách ${keo.distanceBand} km');
    final time = _formatTime(keo.timeWindowStart, keo.timeWindowEnd);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Pressable(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.mic_external_on_rounded,
                        color: AppColors.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            keo.title,
                            style: text.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _modeChip(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textHint.withValues(alpha: 0.72),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (place != null)
                      _meta(context, Icons.place_rounded, place),
                    if (time != null)
                      _meta(context, Icons.schedule_rounded, time),
                    _meta(
                      context,
                      Icons.groups_rounded,
                      '${keo.slotsFilled}/${keo.sizeTarget} người',
                    ),
                    if (keo.hostName != null)
                      _meta(context, Icons.person_rounded, keo.hostName!),
                  ],
                ),
                if (keo.genres.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final genre in keo.genres)
                        _genreChip(context, genre),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.textHint),
      const SizedBox(width: AppSpacing.xs),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _modeChip(BuildContext context) {
    final open = keo.joinMode == 'open';
    final label = open ? 'Mở · vào là tham gia' : 'Cần duyệt';
    final bg = open
        ? AppColors.secondary.withValues(alpha: 0.62)
        : AppColors.tertiaryTint;
    final fg = open ? AppColors.secondaryDark : AppColors.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            open ? Icons.lock_open_rounded : Icons.verified_user_rounded,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _genreChip(BuildContext context, String genre) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
    ),
    child: Text(
      genre,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  String? _formatTime(String? start, String? end) {
    if (start == null || end == null) return null;
    final startAt = DateTime.tryParse(start);
    final endAt = DateTime.tryParse(end);
    if (startAt == null || endAt == null) return null;

    final localStart = startAt.toLocal();
    final localEnd = endAt.toLocal();
    return '${_two(localStart.hour)}:${_two(localStart.minute)}-${_two(localEnd.hour)}:${_two(localEnd.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
