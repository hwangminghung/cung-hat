import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_spacing.dart';
import 'package:cung_hat/shared/widgets/wave_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 240, child: child)),
  ),
);

WaveDividerPainter _painter(WidgetTester tester) {
  final paintFinder = find.descendant(
    of: find.byType(WaveDivider),
    matching: find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is WaveDividerPainter,
    ),
  );
  expect(paintFinder, findsOneWidget);
  return tester.widget<CustomPaint>(paintFinder).painter! as WaveDividerPainter;
}

void main() {
  testWidgets('WaveDivider fills its parent and forwards paint configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(WaveDivider(height: 18, color: AppColors.teal, strokeWidth: 3)),
    );

    final paintFinder = find.descendant(
      of: find.byType(WaveDivider),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(paintFinder), const Size(240, 18));

    final painter = _painter(tester);
    expect(painter.color, AppColors.teal);
    expect(painter.strokeWidth, 3);
    expect(painter.semanticsBuilder, isNull);

    final excluded = tester.widget<ExcludeSemantics>(
      find.descendant(
        of: find.byType(WaveDivider),
        matching: find.byType(ExcludeSemantics),
      ),
    );
    expect(excluded.excluding, isTrue);
  });

  testWidgets('WaveDivider defaults to a light moss tone', (tester) async {
    await tester.pumpWidget(_wrap(WaveDivider()));

    final painter = _painter(tester);
    expect(painter.color, AppColors.secondaryTint);
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(WaveDivider),
              matching: find.byType(CustomPaint),
            ),
          )
          .height,
      AppSpacing.lg,
    );
  });
}
