import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(keo.title, style: text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place != null)
                    _meta(context, Icons.place_outlined, place),
                  _meta(
                    context,
                    Icons.groups_outlined,
                    '${keo.slotsFilled}/${keo.sizeTarget} người',
                  ),
                  if (keo.hostName != null)
                    _meta(context, Icons.person_outline, keo.hostName!),
                ],
              ),
              if (keo.genres.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [for (final g in keo.genres) _genreChip(g)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _genreChip(String g) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
    ),
    child: Text(
      g,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
