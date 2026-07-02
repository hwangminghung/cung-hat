import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/presentation/match_celebration.dart';

void main() {
  testWidgets('shows the match headline and the CTA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MatchCelebration(
          otherName: 'Linh',
          sharedBaitu: const ['s2'],
          onChat: () {},
        ),
      ),
    );

    expect(find.text('Chung gu!'), findsOneWidget);
    expect(find.text('Rủ đi hát'), findsOneWidget);
  });
}
