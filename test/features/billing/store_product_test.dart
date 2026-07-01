import 'package:cung_hat/features/billing/domain/store_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps store product rows and formats VND', () {
    final product = StoreProduct.fromJson(const {
      'sku': 'pro_monthly_ios',
      'type': 'pro',
      'platform': 'ios',
      'store_product_id': 'com.cunghat.pro.monthly',
      'price_minor': 79000,
      'billing_period': 'monthly',
      'entitlement_days': 31,
      'boost_credits': 0,
      'badge': null,
      'sort_order': 10,
    });

    expect(product.sku, 'pro_monthly_ios');
    expect(product.storeProductId, 'com.cunghat.pro.monthly');
    expect(product.priceLabel, '79.000d');
    expect(product.isPro, isTrue);
    expect(product.isBoost, isFalse);
    expect(product.isConsumable, isFalse);
  });

  test('boost products are consumable', () {
    final product = StoreProduct.fromJson(const {
      'sku': 'keo_boost_3_android',
      'type': 'boost',
      'platform': 'android',
      'store_product_id': 'keo_boost_3',
      'price_minor': 79000,
      'billing_period': 'consumable',
      'entitlement_days': null,
      'boost_credits': 3,
      'badge': 'best_value',
      'sort_order': 41,
    });

    expect(product.isBoost, isTrue);
    expect(product.isConsumable, isTrue);
    expect(product.boostCredits, 3);
  });
}
