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
              Row(
                children: [
                  Expanded(child: Text(keo.title, style: text.titleMedium)),
                  if (keo.isBoosted) _boostedChip(),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(alignment: Alignment.centerLeft, child: _modeChip()),
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

  Widget _modeChip() {
    final open = keo.joinMode == 'open';
    final label = open ? 'Mở · vào là tham gia' : 'Cần duyệt';
    final fg = open ? AppColors.primaryDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: open ? AppColors.primaryTint : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: open ? null : Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            open ? Icons.lock_open_outlined : Icons.verified_user_outlined,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _boostedChip() => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.trending_up, size: 13, color: AppColors.primaryDark),
        SizedBox(width: AppSpacing.xs),
        Text(
          'Noi bat',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    ),
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
