import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
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
    required this.term,
    required this.price,
    required this.icon,
    this.highlight = false,
  });

  final String feature;
  final String title;
  final String description;

  /// Ky han: mua mot lan / 24 gio. Bat buoc theo Apple 3.1.2 + Play Payments —
  /// user phai biet co tu dong gia han khong TRUOC khi bam mua.
  final String term;
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

/// Consumable: mua lai duoc nhieu lan, nen khong bao gio hien "Da so huu".
const _consumableTypes = {'boost'};

String formatPriceK(int minor) => '${(minor / 1000).round()}k';

/// Ky han hien duoi mo ta. Toan bo catalog la mua mot lan — khong co thue bao
/// nao trong app, nen khong co gi tu dong gia han.
String _termFor(String type, AppLocalizations? l10n) => type == 'boost'
    ? (l10n?.storeTermBoost ?? 'Mua một lần · hiệu lực 24 giờ')
    : (l10n?.storeTermOneTime ?? 'Mua một lần · vĩnh viễn');

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    // Ket qua thanh toan THAT den tu purchaseStream, khong phai tu nut Mua
    // (nut chi mo man store roi tra ve ngay). Khong co listener nay thi
    // giao dich pending/that bai im lang hoan toan.
    ref.listen<IapEvent?>(iapEventProvider, (previous, next) {
      if (next == null) return;
      final message = switch (next) {
        IapEvent.pending =>
          l10n?.storePending ?? 'Đang chờ xác nhận thanh toán…',
        IapEvent.success =>
          l10n?.storeSuccess ?? 'Mua thành công. Đã mở khóa tính năng.',
        IapEvent.restored => l10n?.storeRestored ?? 'Đã khôi phục giao dịch.',
        IapEvent.failed =>
          l10n?.storeFailed ??
              'Thanh toán không thành công. Bạn chưa bị trừ tiền.',
        IapEvent.deliveryFailed =>
          l10n?.storeDeliveryFailed ??
              'Đã thanh toán nhưng chưa mở khóa được. Hệ thống sẽ tự thử lại '
                  '— liên hệ hỗ trợ nếu vẫn chưa mở.',
        // User tu bam huy: khong can bao lai cho ho.
        IapEvent.canceled => null,
      };
      ref.read(iapEventProvider.notifier).state = null;
      if (message == null || !context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });

    // Gia store localized; rong khi khong hoi duoc store -> rot ve gia catalog.
    final storePrices = ref
        .watch(storePricesProvider)
        .maybeWhen(data: (m) => m, orElse: () => const <String, String>{});

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
                          child: Icon(
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                                  term: _termFor(product.type, l10n),
                                  price:
                                      storePrices[product.type] ??
                                      formatPriceK(product.priceMinor),
                                  icon:
                                      _copyFor(product.type, l10n)?.icon ??
                                      Icons.star,
                                  highlight:
                                      _copyFor(product.type, l10n)?.highlight ??
                                      false,
                                ),
                                // Consumable mua lai duoc; chi non-consumable
                                // moi khoa lai khi da so huu.
                                owned:
                                    !_consumableTypes.contains(product.type) &&
                                    ref.watch(
                                      hasEntitlementProvider(product.type),
                                    ),
                                buyLabel: l10n?.storeBuy ?? 'Mua',
                                ownedLabel: l10n?.storeOwned ?? 'Đã sở hữu',
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
                      error: (error, stackTrace) => _StoreErrorState(
                        title:
                            l10n?.storeLoadError ?? 'Không tải được cửa hàng',
                        retryLabel: l10n?.commonRetry ?? 'Thử lại',
                        onRetry: () => ref.invalidate(storeProductsProvider),
                      ),
                    ),
                const _StorePurchaseFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [AUDIT P1-b,c,d] Ba thu store bat buoc phai co NGAY TREN man thanh toan:
/// nut khoi phuc mua hang (Apple 3.1.1), link Dieu khoan + Chinh sach bao mat
/// (Apple 3.1.2), va noi ro co tu dong gia han khong.
class _StorePurchaseFooter extends ConsumerWidget {
  const _StorePurchaseFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    Future<void> restore() async {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.storeRestoreStarted ??
                'Đang kiểm tra các giao dịch trước đây…',
          ),
        ),
      );
      final ok = await ref.read(iapControllerProvider).restore();
      // Thanh cong thi ket qua ve qua purchaseStream (IapEvent.restored),
      // o day chi bao khi khong goi duoc store.
      if (!ok && context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n?.storeRestoreError ??
                  'Không kết nối được cửa hàng. Thử lại sau.',
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WaveDivider(),
          const SizedBox(height: AppSpacing.lg),
          _StoreButtonShadow(
            child: SizedBox(
              height: AppSpacing.buttonHeight,
              child: OutlinedButton(
                key: const Key('store_restore_button'),
                onPressed: restore,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                  side: BorderSide(color: AppColors.ink, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusButton,
                    ),
                  ),
                ),
                child: Text(l10n?.storeRestore ?? 'Khôi phục mua hàng'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n?.storeNoAutoRenew ??
                'Tất cả các gói đều là mua một lần. Đây không phải thuê bao và '
                    'không tự động gia hạn. Việc hoàn tiền do tài khoản App Store '
                    'hoặc Google Play của bạn xử lý.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n?.storeLegalIntro ?? 'Khi mua, bạn đồng ý với:',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                key: const Key('store_terms_link'),
                onPressed: () => context.push('/legal/tos'),
                child: Text(l10n?.settingsTerms ?? 'Điều khoản sử dụng'),
              ),
              TextButton(
                key: const Key('store_privacy_link'),
                onPressed: () => context.push('/legal/privacy'),
                child: Text(l10n?.privacyTitle ?? 'Chính sách bảo mật'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreErrorState extends StatelessWidget {
  const _StoreErrorState({
    required this.title,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EmptyState(
          icon: Icons.wifi_off_rounded,
          title: title,
          onAction: onRetry,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Semantics(
            label: retryLabel,
            button: true,
            onTap: onRetry,
            excludeSemantics: true,
            child: _StoreButtonShadow(
              child: SizedBox(
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: onRetry,
                  style: _storeCtaStyle(),
                  child: Text(retryLabel),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

ButtonStyle _storeCtaStyle() => FilledButton.styleFrom(
  backgroundColor: AppColors.primary,
  foregroundColor: AppColors.onPrimary,
  minimumSize: const Size(0, AppSpacing.buttonHeight),
  textStyle: const TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.05,
  ),
  side: BorderSide(color: AppColors.ink, width: 2),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
  ),
);

class _StoreButtonShadow extends StatelessWidget {
  const _StoreButtonShadow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        boxShadow: [AppShadows.hard],
      ),
      child: child,
    );
  }
}

class _UpgradeTile extends StatelessWidget {
  const _UpgradeTile({
    required this.upgrade,
    required this.onBuy,
    required this.owned,
    required this.buyLabel,
    required this.ownedLabel,
  });

  final _Upgrade upgrade;
  final VoidCallback onBuy;
  final bool owned;
  final String buyLabel;
  final String ownedLabel;

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
                  const SizedBox(height: AppSpacing.xs),
                  // Ky han nam o cot trai (co the co dan) thay vi canh gia —
                  // cot gia rong 68dp se tran o textScale 1.4.
                  Text(
                    upgrade.term,
                    key: Key('store_term_${upgrade.feature}'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: contentColor,
                      fontWeight: FontWeight.w700,
                    ),
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
                _StoreButtonShadow(
                  child: SizedBox(
                    height: AppSpacing.buttonHeight,
                    child: FilledButton(
                      onPressed: owned ? null : onBuy,
                      style: _storeCtaStyle(),
                      child: Text(owned ? ownedLabel : buyLabel),
                    ),
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
