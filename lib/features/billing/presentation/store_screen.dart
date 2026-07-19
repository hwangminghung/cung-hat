import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hard_card.dart';
import '../../../shared/widgets/responsive_frame.dart';
import '../../../shared/widgets/skeleton.dart';
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
/// [L10N] title/description qua l10n (fallback VI); icon/highlight tinh.
///
/// GIA DINH: 1 row/type/platform trong products. Neu them SKU thu 2 cung type
/// (vd pro lifetime), PHAI chuyen key sang sku/storeProductId — xem audit AH-T9.
({String title, String description, IconData icon, bool highlight})? _copyFor(
  String type,
  AppLocalizations? l10n,
) => switch (type) {
  'pro' => (
    title: l10n?.upsellCta ?? 'Nâng cấp Pro',
    description:
        l10n?.storeProDesc ??
        'Tạo kèo, tham gia không giới hạn và mở mọi tính năng trả phí.',
    icon: Icons.workspace_premium_rounded,
    highlight: true,
  ),
  'boost' => (
    title: l10n?.boostTitle ?? 'Đẩy kèo lên top',
    description:
        l10n?.storeBoostDesc ?? 'Đưa kèo của bạn lên đầu bảng trong 24 giờ.',
    icon: Icons.local_fire_department_rounded,
    highlight: false,
  ),
  'see_likes' => (
    title: l10n?.seeLikesTitle ?? 'Xem ai đã thích bạn',
    description:
        l10n?.storeSeeLikesDesc ?? 'Mở khóa danh sách người đã thả tim bạn.',
    icon: Icons.favorite_rounded,
    highlight: false,
  ),
  'premium_filters' => (
    title: l10n?.filtersTitle ?? 'Bộ lọc nâng cao',
    description:
        l10n?.storeFiltersDesc ??
        'Lọc theo gu nhạc, độ tuổi, khu vực và trạng thái hoạt động.',
    icon: Icons.tune_rounded,
    highlight: false,
  ),
  _ => null,
};

const _order = ['pro', 'boost', 'see_likes', 'premium_filters'];

String formatPriceK(int minor) => '${(minor / 1000).round()}k';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.storeTitle ?? 'Nâng cấp')),
      body: ResponsiveFrame(
        child: KeyedSubtree(
          key: const Key('screen_21_store'),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: Column(
              children: [
                HardCard(
                  key: const Key('store_pro_hero'),
                  color: AppColors.ink,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusCard,
                            ),
                          ),
                          child: const Icon(
                            Icons.graphic_eq_rounded,
                            color: AppColors.ink,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n?.appTitle ?? 'Cùng Hát'} Pro',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: AppColors.surface),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n?.storeHeroSub ??
                                    'Mở khóa các công cụ giúp kèo lên nhanh và đúng người.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.surface),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: WaveDivider(),
                ),
                ref
                    .watch(storeProductsProvider)
                    .when(
                      data: (products) {
                        final sorted = [...products]
                          ..sort((a, b) {
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
                                  title:
                                      _copyFor(product.type, l10n)?.title ??
                                      product.type,
                                  description:
                                      _copyFor(
                                        product.type,
                                        l10n,
                                      )?.description ??
                                      '',
                                  price: formatPriceK(product.priceMinor),
                                  icon:
                                      _copyFor(product.type, l10n)?.icon ??
                                      Icons.star,
                                  highlight:
                                      _copyFor(product.type, l10n)?.highlight ??
                                      false,
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
                                      SnackBar(
                                        content: Text(
                                          l10n?.storeOpenError ??
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
                      loading: () => const Column(
                        children: [
                          SkeletonCard(),
                          SkeletonCard(),
                          SkeletonCard(),
                        ],
                      ),
                      error: (error, stackTrace) => EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title:
                            l10n?.storeLoadError ?? 'Không tải được cửa hàng',
                        actionLabel: l10n?.commonRetry ?? 'Thử lại',
                        onAction: () => ref.invalidate(storeProductsProvider),
                      ),
                    ),
              ],
            ),
          ),
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
    final cardColor = upgrade.highlight ? AppColors.ink : AppColors.surface;
    final contentColor = upgrade.highlight ? AppColors.surface : AppColors.ink;
    final iconColor = upgrade.highlight
        ? AppColors.secondary
        : AppColors.primaryTint;
    final priceColor = upgrade.highlight ? AppColors.secondary : AppColors.teal;

    return HardCard(
      key: Key('store_product_${upgrade.feature}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor,
                border: Border.all(color: AppColors.ink, width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: Icon(upgrade.icon, color: AppColors.ink),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upgrade.title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: contentColor),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    upgrade.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: contentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 68),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: priceColor,
                    border: Border.all(color: AppColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusButton,
                    ),
                  ),
                  child: Text(
                    upgrade.price,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onBuy,
                    child: const Text('Mua'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
