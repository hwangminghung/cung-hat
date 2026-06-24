import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/presentation/safety_toolkit.dart';

class _MockRepo extends Mock implements PlanRepository {}

void main() {
  testWidgets('tapping "Tôi đã tới" calls checkInArrived', (tester) async {
    final repo = _MockRepo();
    when(() => repo.checkInArrived('p1')).thenAnswer((_) async {});
    await tester.pumpWidget(ProviderScope(
      overrides: [planRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: SafetyToolkit(planId: 'p1'))),
    ));
    await tester.tap(find.byKey(const Key('checkin_btn')));
    await tester.pump();
    verify(() => repo.checkInArrived('p1')).called(1);
  });
}
