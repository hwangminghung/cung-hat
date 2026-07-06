import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/presentation/swipe_overlays.dart';

void main() {
  Future<void> pump(WidgetTester t, double h, double v) => t.pumpWidget(
        MaterialApp(
          home: SwipeOverlays(
            hProgress: h,
            vProgress: v,
            child: const SizedBox(width: 300, height: 400),
          ),
        ),
      );

  double opacityOf(WidgetTester t, Key key) =>
      t.widget<Opacity>(find.byKey(key)).opacity;

  testWidgets('kéo phải hiện THÍCH theo tiến độ, không hiện BỎ QUA',
      (tester) async {
    await pump(tester, 0.6, 0);
    expect(opacityOf(tester, const Key('overlay_like')), closeTo(0.6, 0.01));
    expect(find.byKey(const Key('overlay_nope')), findsNothing);
    expect(find.text('THÍCH'), findsOneWidget);
  });

  testWidgets('kéo trái hiện BỎ QUA', (tester) async {
    await pump(tester, -0.8, 0);
    expect(opacityOf(tester, const Key('overlay_nope')), closeTo(0.8, 0.01));
    expect(find.byKey(const Key('overlay_like')), findsNothing);
  });

  testWidgets('kéo lên hiện SIÊU THÍCH, bị triệt khi kéo ngang mạnh',
      (tester) async {
    await pump(tester, 0, -0.7);
    expect(opacityOf(tester, const Key('overlay_super')), closeTo(0.7, 0.01));
    await pump(tester, -0.9, -0.7);
    expect(opacityOf(tester, const Key('overlay_super')), lessThan(0.1));
  });

  testWidgets('progress ngoài [-1,1] bị clamp', (tester) async {
    await pump(tester, 1.4, 0);
    expect(opacityOf(tester, const Key('overlay_like')), 1.0);
  });

  testWidgets('card được bọc RepaintBoundary, stamp ẩn không được build',
      (tester) async {
    await pump(tester, 0, 0);
    expect(
      find.descendant(
        of: find.byType(SwipeOverlays),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('overlay_like')), findsNothing);
    expect(find.byKey(const Key('overlay_nope')), findsNothing);
    expect(find.byKey(const Key('overlay_super')), findsNothing);
  });
}
