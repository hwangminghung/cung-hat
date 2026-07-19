import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/domain/venue_suggestion.dart';
import 'package:cung_hat/features/plan/presentation/plan_screen.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/responsive_frame.dart';
import 'package:cung_hat/shared/widgets/skeleton.dart';

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
    expect(find.byKey(const Key('screen_19_plan')), findsOneWidget);
    expect(find.byType(ResponsiveFrame), findsOneWidget);
    expect(find.byKey(const Key('venue_map_surface')), findsOneWidget);
    expect(find.byKey(const Key('venue_marker_v1')), findsOneWidget);
    expect(find.text('Kingdom'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
  });

  testWidgets('uses card skeletons while plan content is loading', (
    tester,
  ) async {
    final repo = _MockRepo();
    final venues = Completer<List<VenueSuggestion>>();
    final plan = Completer<Plan?>();
    when(
      () => repo.nearestVenues('k1', limit: any(named: 'limit')),
    ).thenAnswer((_) => venues.future);
    when(() => repo.currentPlan('k1')).thenAnswer((_) => plan.future);

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
    await tester.pump();

    expect(find.byType(SkeletonCard), findsNWidgets(3));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('provider errors show actionable empty states and retry', (
    tester,
  ) async {
    var venueCalls = 0;
    var planCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearestVenuesProvider.overrideWith((ref, keoId) async {
            venueCalls++;
            if (venueCalls == 1) {
              throw StateError('venues unavailable');
            }
            return const [
              VenueSuggestion(
                id: 'v1',
                name: 'Kingdom',
                address: 'Q1',
                distanceBand: '1-3',
                lat: 10.776,
                lng: 106.7,
              ),
            ];
          }),
          currentPlanProvider.overrideWith((ref, keoId) async {
            planCalls++;
            if (planCalls == 1) {
              throw StateError('plan unavailable');
            }
            return null;
          }),
          keoMidpointProvider.overrideWith((ref, keoId) async => null),
        ],
        child: const MaterialApp(
          home: PlanScreen(keoId: 'k1', isHost: true, useNativeMap: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsNWidgets(2));
    expect(find.text('Tải lại'), findsNWidgets(2));

    await tester.tap(find.text('Tải lại').first);
    await tester.pumpAndSettle();
    expect(planCalls, 2);

    await tester.tap(find.text('Tải lại'));
    await tester.pumpAndSettle();
    expect(venueCalls, 2);
    expect(find.byType(EmptyState), findsNothing);
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

  testWidgets(
    'plan stays responsive at required widths, text scales, and keyboard inset',
    (tester) async {
      final repo = _MockRepo();
      when(
        () => repo.nearestVenues('k1', limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => const [
          VenueSuggestion(
            id: 'v1',
            name: 'Music Box Thủ Đức',
            address: '120 Võ Văn Ngân, Thủ Đức',
            distanceBand: '1-3',
            lat: 10.776,
            lng: 106.7,
          ),
        ],
      );
      when(() => repo.currentPlan('k1')).thenAnswer(
        (_) async => Plan(
          id: 'p1',
          keoId: 'k1',
          venueId: 'v1',
          scheduledAt: '2026-07-17T20:00:00Z',
          status: 'confirmed',
        ),
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final width in const [360.0, 393.0, 430.0]) {
        for (final scale in const [1.0, 1.2, 1.4]) {
          const height = 844.0;
          await tester.binding.setSurfaceSize(Size(width, height));
          final platform = width == 393 && scale == 1.4
              ? TargetPlatform.iOS
              : TargetPlatform.android;
          final keyboardInset = width == 360 && scale == 1.4 ? 240.0 : 0.0;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                planRepositoryProvider.overrideWithValue(repo),
                keoMidpointProvider.overrideWith((ref, keoId) async => null),
              ],
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, height),
                  textScaler: TextScaler.linear(scale),
                  viewInsets: EdgeInsets.only(bottom: keyboardInset),
                  disableAnimations: true,
                ),
                child: MaterialApp(
                  theme: AppTheme.light().copyWith(platform: platform),
                  home: const PlanScreen(
                    keoId: 'k1',
                    isHost: true,
                    useNativeMap: false,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: '${width}dp ×$scale on $platform with inset $keyboardInset',
          );
          expect(find.byKey(const Key('screen_19_plan')), findsOneWidget);
          expect(find.byKey(const Key('venue_map_surface')), findsOneWidget);
          expect(find.byKey(const Key('directions_btn')), findsOneWidget);

          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}
