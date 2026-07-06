import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../keo/domain/keo.dart';

/// Thẻ quảng bá Kèo trộn trong deck Đôi. Vuốt phải = xem chi tiết,
/// vuốt trái = bỏ qua — không quota, không rewind.
class KeoPromoCard extends StatelessWidget {
  const KeoPromoCard({super.key, required this.keo});

  final Keo keo;

  String _hhmm(String? iso) {
    if (iso == null) return '?';
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '?';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text('🎤 Kèo gần bạn',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.onPrimary)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(keo.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppColors.onPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${keo.slotsFilled}/${keo.sizeTarget} chỗ · ${_hhmm(keo.timeWindowStart)}'
            '${keo.distanceBand != null ? ' · cách ${keo.distanceBand} km' : ''}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.9)),
          ),
          if (keo.genres.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(keo.genres.take(3).map((g) => '#$g').join('  '),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.onPrimary)),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('Vuốt phải để xem kèo →',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}
