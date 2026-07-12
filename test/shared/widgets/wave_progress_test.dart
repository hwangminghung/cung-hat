import 'package:cung_hat/shared/widgets/wave_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'WaveProgress paints its waveform bars without throwing and exposes '
    'the percent via semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WaveProgress(progress: 0.75)),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('75')), findsOneWidget);

      semantics.dispose();
    },
  );
}
