import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/presentation/booking_button.dart';

class _MockPlanRepository extends Mock implements PlanRepository {}

void main() {
  late _MockPlanRepository repo;

  Widget wrap() => ProviderScope(
        overrides: [planRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(body: BookingButton(planId: 'p1', venueId: 'v1')),
        ),
      );

  setUp(() {
    repo = _MockPlanRepository();
    when(() => repo.startVenuePayment(
            planId: any(named: 'planId'),
            venueId: any(named: 'venueId'),
            gateway: any(named: 'gateway')))
        .thenAnswer((_) async => 'https://pay/x');
  });

  testWidgets('tap nut -> sheet 2 gateway; chon MoMo -> goi voi momo', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('booking_gw_momo')), findsOneWidget);
    expect(find.byKey(const Key('booking_gw_zalopay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('booking_gw_momo')));
    await tester.pumpAndSettle();
    verify(() => repo.startVenuePayment(planId: 'p1', venueId: 'v1', gateway: 'momo'))
        .called(1);
  });

  testWidgets('chon ZaloPay -> goi voi zalopay', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking_gw_zalopay')));
    await tester.pumpAndSettle();
    verify(() => repo.startVenuePayment(planId: 'p1', venueId: 'v1', gateway: 'zalopay'))
        .called(1);
  });

  testWidgets('loi not_configured -> SnackBar cau hinh', (tester) async {
    when(() => repo.startVenuePayment(
            planId: any(named: 'planId'),
            venueId: any(named: 'venueId'),
            gateway: any(named: 'gateway')))
        .thenThrow(Exception('create-venue-payment failed (503): {error: payment_gateway_not_configured}'));
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking_gw_momo')));
    await tester.pumpAndSettle();
    expect(find.textContaining('chưa được cấu hình'), findsOneWidget);
  });
}
