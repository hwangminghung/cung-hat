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
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 6, 29, 19));
  });

  testWidgets('lists nearest venues with their distance band', (tester) async {
    final repo = _MockRepo();
    when(() => repo.nearestVenues('k1', limit: any(named: 'limit'))).thenAnswer(
      (_) async => const [
        VenueSuggestion(
          id: 'v1',
          name: 'Kingdom',
          address: 'Q1',
          distanceBand: '1-3',
          lat: 10.776,
          lng: 106.7,
        ),
      ],
    );
    when(() => repo.currentPlan('k1')).thenAnswer((_) async => null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planRepositoryProvider.overrideWithValue(repo),
          keoMidpointProvider.overrideWith((ref, keoId) async => null),
        ],
        child: const MaterialApp(
          home: PlanScreen(keoId: 'k1', isHost: true, useNativeMap: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('venue_map_surface')), findsOneWidget);
    expect(find.byKey(const Key('venue_marker_v1')), findsOneWidget);
    expect(find.text('Kingdom'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
  });

  testWidgets('host sees guidance when there are no venue suggestions', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(
      () => repo.nearestVenues('k1', limit: any(named: 'limit')),
    ).thenAnswer((_) async => const <VenueSuggestion>[]);
    when(() => repo.currentPlan('k1')).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planRepositoryProvider.overrideWithValue(repo),
          keoMidpointProvider.overrideWith((ref, keoId) async => null),
        ],
        child: const MaterialApp(
          home: PlanScreen(keoId: 'k1', isHost: true, useNativeMap: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('venues_empty_state')), findsOneWidget);
  });

  testWidgets('host chooses a venue through the redesigned time sheet', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.nearestVenues('k1', limit: any(named: 'limit'))).thenAnswer(
      (_) async => const [
        VenueSuggestion(
          id: 'v1',
          name: 'Kingdom',
          address: 'Q1',
          distanceBand: '<1',
          lat: 10.776,
          lng: 106.7,
        ),
      ],
    );
    when(() => repo.currentPlan('k1')).thenAnswer((_) async => null);
    when(
      () => repo.proposePlan('k1', 'v1', any()),
    ).thenAnswer((_) async => 'p1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planRepositoryProvider.overrideWithValue(repo),
          keoMidpointProvider.overrideWith((ref, keoId) async => null),
        ],
        child: MaterialApp(
          home: PlanScreen(
            keoId: 'k1',
            isHost: true,
            useNativeMap: false,
            debugNow: DateTime(2026, 6, 29, 12),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pick_venue_v1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan_time_sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('plan_time_1900')));
    await tester.tap(find.byKey(const Key('confirm_plan_time_btn')));
    await tester.pumpAndSettle();

    verify(
      () => repo.proposePlan('k1', 'v1', DateTime(2026, 6, 29, 19)),
    ).called(1);
  });
}
