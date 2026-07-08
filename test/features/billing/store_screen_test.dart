import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/billing/data/billing_repository.dart';
import 'package:cung_hat/features/billing/presentation/store_screen.dart';

const _catalog = <StoreProduct>[
  StoreProduct(
    sku: 'pro_android',
    type: 'pro',
    storeProductId: 'pro',
    priceMinor: 199000,
  ),
  StoreProduct(
    sku: 'boost_android',
    type: 'boost',
    storeProductId: 'boost',
    priceMinor: 49000,
  ),
  StoreProduct(
    sku: 'see_likes_android',
    type: 'see_likes',
    storeProductId: 'see_likes',
    priceMinor: 99000,
  ),
  StoreProduct(
    sku: 'filters_android',
    type: 'premium_filters',
    storeProductId: 'filters',
    priceMinor: 79000,
  ),
];

void main() {
  testWidgets(
    'store lists Pro, boost and premium upgrades with catalog pricing',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProductsProvider.overrideWith((ref) async => _catalog),
          ],
          child: const MaterialApp(home: StoreScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nâng cấp Pro'), findsOneWidget);
      expect(find.text('Đẩy kèo lên top'), findsOneWidget);
      expect(find.text('Xem ai đã thích bạn'), findsOneWidget);
      expect(find.text('Bộ lọc nâng cao'), findsOneWidget);
      // Gia THAT tu catalog (products), khong con hardcode client.
      expect(find.text('199k'), findsOneWidget);
      expect(find.text('49k'), findsOneWidget);
      expect(find.text('99k'), findsOneWidget);
      expect(find.text('79k'), findsOneWidget);
      // Tile "Pro tron doi" trung SKU voi 'pro' da bi xoa (catalog chi co 1 dong pro/platform).
      expect(find.textContaining('Pro trọn đời'), findsNothing);
      expect(find.text('699k'), findsNothing);
      expect(find.text('Mua'), findsNWidgets(4));
    },
  );

  testWidgets('error state shows retry button that reloads the catalog', (
    tester,
  ) async {
    // StateError (an Error, not a plain Exception) skips Riverpod's default
    // auto-retry-with-backoff so the AsyncError surfaces on the next frame
    // instead of only after several seconds of retry attempts.
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProductsProvider.overrideWith((ref) async {
            calls++;
            if (calls == 1) throw StateError('network');
            return _catalog;
          }),
        ],
        child: const MaterialApp(home: StoreScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được cửa hàng'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không tải được cửa hàng'), findsNothing);
    expect(find.text('Nâng cấp Pro'), findsOneWidget);
  });

  testWidgets('tiles giu thu tu _order du catalog xao tron; type la xuong cuoi '
      'voi fallback title/icon', (tester) async {
    // Catalog XAO TRON + 1 type la khong co trong _copy.
    const shuffled = <StoreProduct>[
      StoreProduct(
        sku: 'filters_android',
        type: 'premium_filters',
        storeProductId: 'filters',
        priceMinor: 79000,
      ),
      StoreProduct(
        sku: 'unknown_x_android',
        type: 'unknown_x',
        storeProductId: 'unknown_x',
        priceMinor: 10000,
      ),
      StoreProduct(
        sku: 'pro_android',
        type: 'pro',
        storeProductId: 'pro',
        priceMinor: 199000,
      ),
      StoreProduct(
        sku: 'boost_android',
        type: 'boost',
        storeProductId: 'boost',
        priceMinor: 49000,
      ),
      StoreProduct(
        sku: 'see_likes_android',
        type: 'see_likes',
        storeProductId: 'see_likes',
        priceMinor: 99000,
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProductsProvider.overrideWith((ref) async => shuffled),
        ],
        child: const MaterialApp(home: StoreScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Type la: title fallback = chinh type, icon fallback = Icons.star.
    expect(find.text('unknown_x'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);

    // Thu tu render theo _order (pro, boost, see_likes, premium_filters),
    // type la CUOI cung — do dy cua title tang dan.
    double dy(String title) => tester.getTopLeft(find.text(title)).dy;
    final titlesInExpectedOrder = [
      'Nâng cấp Pro',
      'Đẩy kèo lên top',
      'Xem ai đã thích bạn',
      'Bộ lọc nâng cao',
      'unknown_x',
    ];
    for (var i = 0; i < titlesInExpectedOrder.length - 1; i++) {
      expect(
        dy(titlesInExpectedOrder[i]),
        lessThan(dy(titlesInExpectedOrder[i + 1])),
        reason:
            '${titlesInExpectedOrder[i]} phai nam TREN ${titlesInExpectedOrder[i + 1]}',
      );
    }
  });
}
