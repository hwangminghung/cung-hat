import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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

const _upgrades = <_Upgrade>[
  _Upgrade(
    feature: 'pro',
    title: 'Nâng cấp Pro',
    description:
        'Tạo kèo, tham gia không giới hạn và mở mọi tính năng trả phí.',
    price: '99k',
    icon: Icons.workspace_premium_rounded,
    highlight: true,
  ),
  _Upgrade(
    feature: 'pro',
    title: 'Pro trọn đời launch',
    description: 'Một lần mua trong giai đoạn đầu, giữ Pro lâu dài.',
    price: '699k',
    icon: Icons.all_inclusive_rounded,
    highlight: true,
  ),
  _Upgrade(
    feature: 'boost',
    title: 'Đẩy kèo lên top',
    description: 'Đưa kèo của bạn lên đầu bảng trong 24 giờ.',
    price: '29k',
    icon: Icons.local_fire_department_rounded,
  ),
  _Upgrade(
    feature: 'see_likes',
    title: 'Xem ai đã thích bạn',
    description: 'Mở khóa danh sách người đã thả tim bạn.',
    price: '49k',
    icon: Icons.favorite_rounded,
  ),
  _Upgrade(
    feature: 'premium_filters',
    title: 'Bộ lọc nâng cao',
    description: 'Lọc theo gu nhạc, độ tuổi, khu vực và trạng thái hoạt động.',
    price: '39k',
    icon: Icons.tune_rounded,
  ),
];

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
            const SizedBox(height: AppSpacing.lg),
            for (final upgrade in _upgrades)
              _UpgradeTile(
                upgrade: upgrade,
                onBuy: () =>
                    ref.read(iapControllerProvider).buy(upgrade.feature),
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
