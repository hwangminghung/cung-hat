import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/billing/data/billing_repository.dart';
import 'package:cung_hat/features/billing/presentation/store_screen.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/hard_card.dart';
import 'package:cung_hat/shared/widgets/skeleton.dart';

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

Future<void> _pumpStore(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [storeProductsProvider.overrideWith((ref) async => _catalog)],
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const StoreScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

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

      expect(find.byKey(const Key('screen_21_store')), findsOneWidget);
      expect(find.byKey(const Key('store_pro_hero')), findsOneWidget);
      expect(find.byKey(const Key('store_product_pro')), findsOneWidget);
      expect(
        tester.widget(find.byKey(const Key('store_product_pro'))),
        isA<HardCard>(),
      );
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

  testWidgets('loading state uses store card skeletons', (tester) async {
    final catalog = Completer<List<StoreProduct>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProductsProvider.overrideWith((ref) => catalog.future),
        ],
        child: const MaterialApp(home: StoreScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('screen_21_store')), findsOneWidget);
    expect(find.byType(SkeletonCard), findsWidgets);

    catalog.complete(_catalog);
    await tester.pumpAndSettle();
  });

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
    final emptyState = tester.widget<EmptyState>(find.byType(EmptyState));
    expect(emptyState.onAction, isNotNull);

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

  testWidgets('store stays usable at required widths and text scales', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in <double>[360, 393, 430]) {
      for (final scale in <double>[1, 1.2, 1.4]) {
        await _pumpStore(tester, size: Size(width, 800), textScale: scale);

        expect(
          tester.takeException(),
          isNull,
          reason: 'Store overflowed at ${width}dp and ${scale}x text',
        );
        expect(find.byKey(const Key('screen_21_store')), findsOneWidget);
      }
    }
  });

  testWidgets('store renders its presentation on iOS', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpStore(
      tester,
      size: const Size(430, 800),
      textScale: 1.4,
      platform: TargetPlatform.iOS,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('store_product_pro')), findsOneWidget);
  });
}
