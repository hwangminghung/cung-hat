import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../application/billing_providers.dart';
import '../application/iap_controller.dart';

class _Upgrade {
  const _Upgrade({
    required this.feature,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    this.highlight = false,
  });

  final String feature;
  final String title;
  final String description;
  final String price;
  final IconData icon;
  final bool highlight;
}

/// Copy + icon tinh theo type (khong doi thuong xuyen); gia lay tu catalog.
///
/// GIA DINH: 1 row/type/platform trong products. Neu them SKU thu 2 cung type
/// (vd pro lifetime), PHAI chuyen key sang sku/storeProductId — xem audit AH-T9.
const _copy =
    <String, ({String title, String description, IconData icon, bool highlight})>{
  'pro': (
    title: 'Nâng cấp Pro',
    description:
        'Tạo kèo, tham gia không giới hạn và mở mọi tính năng trả phí.',
    icon: Icons.workspace_premium_rounded,
    highlight: true,
  ),
  'boost': (
    title: 'Đẩy kèo lên top',
    description: 'Đưa kèo của bạn lên đầu bảng trong 24 giờ.',
    icon: Icons.local_fire_department_rounded,
    highlight: false,
  ),
  'see_likes': (
    title: 'Xem ai đã thích bạn',
    description: 'Mở khóa danh sách người đã thả tim bạn.',
    icon: Icons.favorite_rounded,
    highlight: false,
  ),
  'premium_filters': (
    title: 'Bộ lọc nâng cao',
    description: 'Lọc theo gu nhạc, độ tuổi, khu vực và trạng thái hoạt động.',
    icon: Icons.tune_rounded,
    highlight: false,
  ),
};

const _order = ['pro', 'boost', 'see_likes', 'premium_filters'];

String formatPriceK(int minor) => '${(minor / 1000).round()}k';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nâng cấp')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        child: Column(
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
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cùng Hát Pro',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.onPrimary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Mở khóa các công cụ giúp kèo lên nhanh và đúng người.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.onPrimary.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: WaveDivider(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ref
                .watch(storeProductsProvider)
                .when(
                  data: (products) {
                    final sorted = [...products]..sort((a, b) {
                      final ia = _order.indexOf(a.type);
                      final ib = _order.indexOf(b.type);
                      return (ia == -1 ? _order.length : ia).compareTo(
                        ib == -1 ? _order.length : ib,
                      );
                    });
                    return Column(
                      children: [
                        for (final product in sorted)
                          _UpgradeTile(
                            upgrade: _Upgrade(
                              feature: product.type,
                              title: _copy[product.type]?.title ?? product.type,
                              description:
                                  _copy[product.type]?.description ?? '',
                              price: formatPriceK(product.priceMinor),
                              icon: _copy[product.type]?.icon ?? Icons.star,
                              highlight:
                                  _copy[product.type]?.highlight ?? false,
                            ),
                            onBuy: () async {
                              final ok = await ref
                                  .read(iapControllerProvider)
                                  .buy(product.type);
                              // [AUDIT C1] buy fail (catalog/store lỗi) trước
                              // đây im lặng — user bấm Mua mà không có gì
                              // xảy ra.
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Không mở được cửa hàng. Thử lại sau.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Column(
                    children: [
                      const Text('Không tải được cửa hàng'),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(storeProductsProvider),
                        child: const Text('Thử lại'),
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

class _UpgradeTile extends StatelessWidget {
  const _UpgradeTile({required this.upgrade, required this.onBuy});

  final _Upgrade upgrade;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final bg = upgrade.highlight ? AppColors.surfaceWarm : AppColors.surface;
    final iconBg = upgrade.highlight
        ? AppColors.primaryTint
        : AppColors.tertiaryTint;
    final iconFg = upgrade.highlight
        ? AppColors.primaryDark
        : AppColors.tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(upgrade.icon, color: iconFg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upgrade.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      upgrade.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                upgrade.price,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: onBuy, child: const Text('Mua')),
          ),
        ],
      ),
    );
  }
}
