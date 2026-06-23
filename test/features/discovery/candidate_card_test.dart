import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_card.dart';

void main() {
  testWidgets('card shows name, distance band, and a monogram when no photo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CandidateCard(
      candidate: Candidate(id: 'u2', displayName: 'Linh', age: 24,
        distanceBand: '1-3', sharedBaitu: ['s2'], verified: true),
    ))));
    expect(find.text('Linh, 24'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
    expect(find.text('L'), findsOneWidget); // monogram fallback (no photo)
  });
}
