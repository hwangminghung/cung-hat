import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/features/billing/presentation/store_screen.dart';

void main() {
  testWidgets('store lists Pro, boost and premium upgrades with pricing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: StoreScreen())),
    );
    await tester.pump();

    expect(find.text('Nâng cấp Pro'), findsWidgets);
    expect(find.text('Đẩy kèo lên top'), findsOneWidget);
    expect(find.text('Xem ai đã thích bạn'), findsOneWidget);
    expect(find.text('Bộ lọc nâng cao'), findsOneWidget);
    expect(find.text('99k'), findsOneWidget);
    expect(find.text('699k'), findsOneWidget);
  });
}
