import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/presentation/booking_button.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import '../../support/presentation_harness.dart';

class _MockPlanRepository extends Mock implements PlanRepository {}

void main() {
  late _MockPlanRepository repo;

  Widget wrap() => ProviderScope(
    overrides: [planRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: BookingButton(planId: 'p1', venueId: 'v1'),
      ),
    ),
  );

  setUp(() {
    // canLaunchUrl goi platform channel that; khong mock thi reply khong bao
    // gio ve trong fake-async -> _busy khong clear -> spinner quay mai ->
    // pumpAndSettle timeout. Mock tra false de flow ket thuc gon.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async => false,
        );
    repo = _MockPlanRepository();
    when(
      () => repo.startVenuePayment(
        planId: any(named: 'planId'),
        venueId: any(named: 'venueId'),
        gateway: any(named: 'gateway'),
      ),
    ).thenAnswer((_) async => 'https://pay/x');
  });

  testWidgets('tap nut -> sheet 2 gateway; chon MoMo -> goi voi momo', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen_20_booking_payment')), findsOneWidget);
    expect(find.byKey(const Key('booking_gw_momo')), findsOneWidget);
    expect(find.byKey(const Key('booking_gw_zalopay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('booking_gw_momo')));
    await tester.pumpAndSettle();
    verify(
      () =>
          repo.startVenuePayment(planId: 'p1', venueId: 'v1', gateway: 'momo'),
    ).called(1);
  });

  testWidgets('chon ZaloPay -> goi voi zalopay', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking_gw_zalopay')));
    await tester.pumpAndSettle();
    verify(
      () => repo.startVenuePayment(
        planId: 'p1',
        venueId: 'v1',
        gateway: 'zalopay',
      ),
    ).called(1);
  });

  testWidgets('loi not_configured -> SnackBar cau hinh', (tester) async {
    when(
      () => repo.startVenuePayment(
        planId: any(named: 'planId'),
        venueId: any(named: 'venueId'),
        gateway: any(named: 'gateway'),
      ),
    ).thenThrow(
      const FunctionException(
        status: 503,
        details: {'error': 'payment_gateway_not_configured'},
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking_gw_momo')));
    await tester.pumpAndSettle();
    expect(find.textContaining('chưa được cấu hình'), findsOneWidget);
  });

  testWidgets('dong sheet khong chon -> khong goi thanh toan', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('booking_gw_momo')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // barrier -> dismiss sheet
    await tester.pumpAndSettle();
    verifyNever(
      () => repo.startVenuePayment(
        planId: any(named: 'planId'),
        venueId: any(named: 'venueId'),
        gateway: any(named: 'gateway'),
      ),
    );
  });

  testWidgets('payment sheet stays usable on the compact iOS target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await pumpPresentation(
      tester,
      child: ProviderScope(
        overrides: [planRepositoryProvider.overrideWithValue(repo)],
        child: const Scaffold(
          body: BookingButton(planId: 'p1', venueId: 'v1'),
        ),
      ),
      size: const Size(360, 640),
      textScale: 1.4,
      platform: TargetPlatform.iOS,
      disableAnimations: true,
    );
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_20_booking_payment')), findsOneWidget);
    for (final key in const [
      Key('booking_gw_momo'),
      Key('booking_gw_zalopay'),
    ]) {
      final target = find.byKey(key);
      expect(target.hitTestable(), findsOneWidget);
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    }
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
