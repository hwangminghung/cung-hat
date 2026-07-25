import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo_member.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/domain/venue_suggestion.dart';
import 'package:cung_hat/features/plan/presentation/plan_screen.dart';
import 'package:cung_hat/features/plan/presentation/safety_toolkit.dart';

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
      when(
        () => repo.nearestVenues('k1', limit: any(named: 'limit')),
      ).thenAnswer((_) async => venues);
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

  // [AUDIT] scheduled_at la String ISO doc thang tu DB va chua tung duoc parse,
  // nen man hinh in ra '2026-07-12T19:00:00.000Z' cho user doc.
  testWidgets('gio hen hien dang doc duoc, khong phai ISO tho', (tester) async {
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
    when(
      () => repo.nearestVenues('k1', limit: any(named: 'limit')),
    ).thenAnswer((_) async => venues);
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

    expect(find.textContaining('2026-07-12T'), findsNothing);
    expect(find.textContaining('Z'), findsNothing);
    // Khong assert gio cu the: CI chay UTC, may dev UTC+7.
    expect(
      find.textContaining(RegExp(r'\d{2}:\d{2} · \d{1,2}/\d{1,2}/\d{4}')),
      findsOneWidget,
    );
  });

  // ── [DEBT] huy ke hoach + danh sach da xac nhan + safety khi proposed ─────

  Future<_MockRepo> pumpPlan(
    WidgetTester tester, {
    required bool isHost,
    String status = 'proposed',
  }) async {
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
    when(
      () => repo.nearestVenues('k1', limit: any(named: 'limit')),
    ).thenAnswer((_) async => venues);
    when(() => repo.currentPlan('k1')).thenAnswer(
      (_) async => Plan(
        id: 'p1',
        keoId: 'k1',
        venueId: 'v1',
        scheduledAt: '2026-07-12T19:00:00Z',
        status: status,
      ),
    );
    when(() => repo.cancelPlan('p1')).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planRepositoryProvider.overrideWithValue(repo),
          keoMidpointProvider.overrideWith((ref, keoId) async => null),
          planConfirmationsProvider.overrideWith(
            (ref, planId) async => {'host-1'},
          ),
          keoRosterProvider.overrideWith(
            (ref, keoId) async => const [
              KeoMember(
                userId: 'host-1',
                displayName: 'Chủ Kèo',
                role: 'host',
                joinStatus: 'approved',
                confirmed: true,
              ),
              KeoMember(
                userId: 'mem-2',
                displayName: 'Thành Viên',
                joinStatus: 'approved',
                confirmed: true,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: PlanScreen(keoId: 'k1', isHost: isHost, useNativeMap: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('host thay nut Huỷ kế hoạch; xac nhan dialog -> goi RPC', (
    tester,
  ) async {
    final repo = await pumpPlan(tester, isHost: true);

    final cancelBtn = find.byKey(const Key('cancel_plan_btn'));
    expect(cancelBtn, findsOneWidget);

    await tester.ensureVisible(cancelBtn);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();
    expect(find.text('Huỷ kế hoạch này?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel_plan_confirm_btn')));
    await tester.pumpAndSettle();
    verify(() => repo.cancelPlan('p1')).called(1);
  });

  testWidgets('member KHONG thay nut huy', (tester) async {
    await pumpPlan(tester, isHost: false);
    expect(find.byKey(const Key('cancel_plan_btn')), findsNothing);
  });

  testWidgets('dong "Đã xác nhận n/tổng" hien ten nguoi da dong y', (
    tester,
  ) async {
    await pumpPlan(tester, isHost: false);
    final row = find.byKey(const Key('plan_confirmations_row'));
    expect(row, findsOneWidget);
    final text = tester.widget<Text>(row).data ?? '';
    expect(text, contains('Đã xác nhận 1/2'));
    expect(text, contains('Chủ Kèo'));
    expect(text, isNot(contains('Thành Viên')));
  });

  testWidgets('SafetyToolkit hien ca khi plan moi proposed', (tester) async {
    // [DEBT] Truoc day chi hien khi confirmed — giai doan can nhac gap
    // nguoi la thi khong co loi an toan nao.
    await pumpPlan(tester, isHost: false, status: 'proposed');
    expect(find.byType(SafetyToolkit), findsOneWidget);
  });
}
