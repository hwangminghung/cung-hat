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
  testWidgets(
    'v1: confirmed plan shows Chỉ đường instead of Đặt phòng (BOOKING_ENABLED off by default)',
    (tester) async {
      final repo = _MockRepo();
      const venues = [
        VenueSuggestion(
          id: 'v1',
          name: 'Music Box Thủ Đức',
          address: '120 Võ Văn Ngân',
          lat: 10.85,
          lng: 106.77,
        ),
      ];
      final plan = Plan(
        id: 'p1',
        keoId: 'k1',
        venueId: 'v1',
        scheduledAt: '2026-07-12T19:00:00Z',
        status: 'confirmed',
      );
      when(() => repo.nearestVenues('k1', limit: any(named: 'limit')))
          .thenAnswer((_) async => venues);
      when(() => repo.currentPlan('k1')).thenAnswer((_) async => plan);

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

      expect(find.text('Chỉ đường'), findsOneWidget);
      expect(find.byKey(const Key('directions_btn')), findsOneWidget);
      expect(find.textContaining('Đặt phòng'), findsNothing);
    },
  );
}
