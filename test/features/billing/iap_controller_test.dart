import 'package:cung_hat/features/billing/application/iap_controller.dart';
import 'package:cung_hat/features/billing/domain/store_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('purchase mode uses consumable for boost products', () {
    const product = StoreProduct(
      sku: 'keo_boost_24h_ios',
      type: 'boost',
      platform: 'ios',
      storeProductId: 'com.cunghat.keo.boost.24h',
      priceMinor: 29000,
      billingPeriod: 'consumable',
      boostCredits: 1,
      sortOrder: 40,
    );

    expect(purchaseModeFor(product), PurchaseMode.consumable);
  });

  test('purchase mode uses non-consumable/subscription path for Pro products', () {
    const product = StoreProduct(
      sku: 'pro_monthly_ios',
      type: 'pro',
      platform: 'ios',
      storeProductId: 'com.cunghat.pro.monthly',
      priceMinor: 79000,
      billingPeriod: 'monthly',
      entitlementDays: 31,
      boostCredits: 0,
      sortOrder: 10,
    );

    expect(purchaseModeFor(product), PurchaseMode.nonConsumable);
  });
}
