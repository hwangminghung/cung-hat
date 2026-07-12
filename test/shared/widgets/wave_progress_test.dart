import 'package:cung_hat/shared/widgets/wave_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(double progress) =>
    MaterialApp(home: Scaffold(body: WaveProgress(progress: progress)));

WaveProgressPainter _painter(WidgetTester tester) {
  final paintFinder = find.descendant(
    of: find.byType(WaveProgress),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint && widget.painter is WaveProgressPainter,
    ),
  );
  expect(paintFinder, findsOneWidget);
  return tester.widget<CustomPaint>(paintFinder).painter!
      as WaveProgressPainter;
}

void main() {
  testWidgets(
    'WaveProgress paints its waveform bars without throwing and exposes '
    'the percent via semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(_wrap(0.75));

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('75')), findsOneWidget);

      semantics.dispose();
    },
  );

  testWidgets('WaveProgress progress 0.0: no bar done, semantics 0%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(0));

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Hồ sơ hoàn thiện 0%'), findsOneWidget);

    // Hồ sơ mới (0%) không được tô sẵn vạch nào — kể cả vạch index 0.
    final painter = _painter(tester);
    for (var i = 0; i < WaveProgressPainter.barCount; i++) {
      expect(painter.isBarDone(i), isFalse, reason: 'bar $i at progress 0.0');
    }

    semantics.dispose();
  });

  testWidgets('WaveProgress progress 1.0: every bar done, semantics 100%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(1));

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Hồ sơ hoàn thiện 100%'), findsOneWidget);

    final painter = _painter(tester);
    for (var i = 0; i < WaveProgressPainter.barCount; i++) {
      expect(painter.isBarDone(i), isTrue, reason: 'bar $i at progress 1.0');
    }

    semantics.dispose();
  });
}
