import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/billing/domain/store_product.dart';
import 'package:cung_hat/features/billing/presentation/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('store groups Pro and Boost products from server catalog',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storeProductsProvider.overrideWith((ref) async => const [
              StoreProduct(
                sku: 'pro_monthly_ios',
                type: 'pro',
                platform: 'ios',
                storeProductId: 'com.cunghat.pro.monthly',
                priceMinor: 79000,
                billingPeriod: 'monthly',
                entitlementDays: 31,
                boostCredits: 0,
                sortOrder: 10,
              ),
              StoreProduct(
                sku: 'pro_lifetime_launch_ios',
                type: 'pro',
                platform: 'ios',
                storeProductId: 'com.cunghat.pro.lifetime.launch',
                priceMinor: 249000,
                billingPeriod: 'lifetime',
                boostCredits: 0,
                badge: 'launch',
                sortOrder: 30,
              ),
              StoreProduct(
                sku: 'keo_boost_3_ios',
                type: 'boost',
                platform: 'ios',
                storeProductId: 'com.cunghat.keo.boost.3',
                priceMinor: 79000,
                billingPeriod: 'consumable',
                boostCredits: 3,
                badge: 'best_value',
                sortOrder: 41,
              ),
            ]),
      ],
      child: const MaterialApp(home: StoreScreen()),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('79.000d / thang'), findsOneWidget);
    expect(find.text('249.000d tron doi'), findsOneWidget);
    expect(find.text('Day keo'), findsOneWidget);
    expect(find.text('3 luot day'), findsOneWidget);
  });

  testWidgets('store hides lifetime when server omits it', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storeProductsProvider.overrideWith((ref) async => const [
              StoreProduct(
                sku: 'pro_monthly_ios',
                type: 'pro',
                platform: 'ios',
                storeProductId: 'com.cunghat.pro.monthly',
                priceMinor: 79000,
                billingPeriod: 'monthly',
                entitlementDays: 31,
                boostCredits: 0,
                sortOrder: 10,
              ),
            ]),
      ],
      child: const MaterialApp(home: StoreScreen()),
    ));

    await tester.pumpAndSettle();

    expect(find.textContaining('tron doi'), findsNothing);
    expect(find.text('79.000d / thang'), findsOneWidget);
  });
}
