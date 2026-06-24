import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/domain/venue_suggestion.dart';
import 'package:cung_hat/features/plan/presentation/plan_screen.dart';

class _MockRepo extends Mock implements PlanRepository {}

void main() {
  testWidgets('lists nearest venues with their distance band', (tester) async {
    final repo = _MockRepo();
    when(() => repo.nearestVenues('k1', limit: any(named: 'limit'))).thenAnswer((_) async =>
        const [VenueSuggestion(id: 'v1', name: 'Kingdom', address: 'Q1', distanceBand: '1-3')]);
    when(() => repo.currentPlan('k1')).thenAnswer((_) async => null);
    await tester.pumpWidget(ProviderScope(
      overrides: [planRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: PlanScreen(keoId: 'k1', isHost: true)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Kingdom'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
  });
}
