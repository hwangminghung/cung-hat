import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/domain/keo_member.dart';
import 'package:cung_hat/features/keo/presentation/keo_detail_screen.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:cung_hat/shared/widgets/gradient_button.dart';
import 'package:cung_hat/shared/widgets/stamp_chip.dart';
import 'package:cung_hat/shared/widgets/ticket_card.dart';
import 'package:cung_hat/core/analytics/analytics_service.dart';
import 'package:cung_hat/shared/widgets/wave_divider.dart';

import '../../support/analytics_fakes.dart';

class _MockRepo extends Mock implements KeoRepository {}

void main() {
  testWidgets('Xin vào kèo thành công → log keo_join_request (P0-3)', (
    tester,
  ) async {
    final repo = _MockRepo();
    final analytics = RecordingAnalytics();
    when(() => repo.roster('k1')).thenAnswer(
      (_) async => const [
        KeoMember(
          userId: 'u1',
          displayName: 'Mai',
          role: 'host',
          joinStatus: 'approved',
        ),
      ],
    );
    when(() => repo.requestJoin('k1')).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keoRepositoryProvider.overrideWithValue(repo),
          myProfileProvider.overrideWith((ref) => Future<Profile?>.value(null)),
          analyticsProvider.overrideWithValue(analytics),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request_join_btn')));
    await tester.pumpAndSettle();
    expect(analytics.events, ['keo_join_request']);
  });
  testWidgets('renders roster and Xin vào kèo button', (tester) async {
    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer(
      (_) async => const [
        KeoMember(
          userId: 'u1',
          displayName: 'Mai',
          verified: true,
          role: 'host',
          joinStatus: 'approved',
        ),
      ],
    );
    when(() => repo.requestJoin('k1')).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keoRepositoryProvider.overrideWithValue(repo),
          myProfileProvider.overrideWith((ref) => Future<Profile?>.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen_14_keo_detail')), findsOneWidget);
    expect(find.text('Mai'), findsOneWidget);
    expect(find.byKey(const ValueKey('u1')), findsOneWidget);
    expect(find.byType(TicketCard), findsOneWidget);
    expect(find.widgetWithText(StampChip, 'Chủ kèo'), findsOneWidget);
    expect(find.byType(WaveDivider), findsWidgets);
    expect(find.byKey(const Key('request_join_btn')), findsOneWidget);
    expect(find.widgetWithText(GradientButton, 'Xin vào kèo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('request_join_btn')));
    await tester.pump();
    verify(() => repo.requestJoin('k1')).called(1);
  });

  testWidgets('approved member keeps share confirm chat plan and leave gates', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer(
      (_) async => const [
        KeoMember(
          userId: 'host',
          displayName: 'Mai',
          role: 'host',
          joinStatus: 'approved',
        ),
        KeoMember(userId: 'me', displayName: 'An', joinStatus: 'approved'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keoRepositoryProvider.overrideWithValue(repo),
          myProfileProvider.overrideWith(
            (ref) => Future<Profile?>.value(const Profile(id: 'me')),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('keo_share_btn')), findsOneWidget);
    expect(find.byKey(const Key('confirm_keo_btn')), findsOneWidget);
    expect(find.byKey(const Key('open_keo_chat_btn')), findsOneWidget);
    expect(find.byKey(const Key('view_plan_btn')), findsOneWidget);
    expect(find.text('Rời kèo'), findsOneWidget);
    expect(find.byKey(const Key('request_join_btn')), findsNothing);
    expect(find.byKey(const Key('host_pick_venue_btn')), findsNothing);
  });

  testWidgets('host keeps share moderation chat and venue-plan gates', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer(
      (_) async => const [
        KeoMember(
          userId: 'me',
          displayName: 'Mai',
          role: 'host',
          joinStatus: 'approved',
        ),
        KeoMember(
          userId: 'pending',
          displayName: 'An',
          joinStatus: 'requested',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keoRepositoryProvider.overrideWithValue(repo),
          myProfileProvider.overrideWith(
            (ref) => Future<Profile?>.value(const Profile(id: 'me')),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('keo_share_btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending')), findsOneWidget);
    expect(find.byTooltip('Duyệt'), findsOneWidget);
    expect(find.byTooltip('Từ chối'), findsOneWidget);
    expect(find.text('1 người trong kèo'), findsOneWidget);
    expect(find.text('2 người trong kèo'), findsNothing);
    expect(find.byKey(const Key('open_keo_chat_btn')), findsOneWidget);
    expect(find.byKey(const Key('host_pick_venue_btn')), findsOneWidget);
    expect(find.byKey(const Key('confirm_keo_btn')), findsNothing);
    expect(find.byKey(const Key('view_plan_btn')), findsNothing);
    expect(find.text('Rời kèo'), findsNothing);
  });

  testWidgets('detail stays scrollable at 320px with large text', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer(
      (_) async => const [
        KeoMember(
          userId: 'me',
          displayName: 'Mai',
          role: 'host',
          joinStatus: 'approved',
        ),
        KeoMember(
          userId: 'pending',
          displayName: 'Nguyễn Hoàng An',
          joinStatus: 'requested',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keoRepositoryProvider.overrideWithValue(repo),
          myProfileProvider.overrideWith(
            (ref) => Future<Profile?>.value(const Profile(id: 'me')),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(2),
            ),
            child: KeoDetailScreen(keoId: 'k1', title: 'Hát tối thứ Bảy'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byTooltip('Duyệt'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final approveTop = tester.getTopLeft(find.byTooltip('Duyệt'));
    final declineTop = tester.getTopLeft(find.byTooltip('Từ chối'));
    expect(approveTop.dy, lessThan(declineTop.dy));
    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('join action stays reachable at 360dp and 1.4x text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer(
      (_) async => const [
        KeoMember(
          userId: 'host',
          displayName: 'Mai',
          role: 'host',
          joinStatus: 'approved',
        ),
        KeoMember(
          userId: 'member',
          displayName: 'Nguyễn Hoàng An',
          joinStatus: 'approved',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keoRepositoryProvider.overrideWithValue(repo),
          myProfileProvider.overrideWith((ref) => Future<Profile?>.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(360, 844),
              textScaler: TextScaler.linear(1.4),
              disableAnimations: true,
            ),
            child: KeoDetailScreen(keoId: 'k1', title: 'Hát tối thứ Bảy'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final joinButton = find.byKey(const Key('request_join_btn'));
    await tester.scrollUntilVisible(
      joinButton,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('screen_14_keo_detail')), findsOneWidget);
    expect(joinButton.hitTestable(), findsOneWidget);
  });

  testWidgets(
    'confirmed member sees state chip and no confirm button (mockup 14)',
    (tester) async {
      final repo = _MockRepo();
      when(() => repo.roster('k1')).thenAnswer(
        (_) async => const [
          KeoMember(
            userId: 'host',
            displayName: 'Mai',
            role: 'host',
            joinStatus: 'approved',
            confirmed: true,
          ),
          KeoMember(
            userId: 'me',
            displayName: 'An',
            joinStatus: 'approved',
            confirmed: true,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keoRepositoryProvider.overrideWithValue(repo),
            myProfileProvider.overrideWith(
              (ref) => Future<Profile?>.value(const Profile(id: 'me')),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirm_keo_btn')), findsNothing);
      expect(find.byKey(const Key('confirmed_state_btn')), findsOneWidget);
      expect(find.widgetWithText(StampChip, 'Đã xác nhận'), findsOneWidget);
      // Host giữ chip 'Chủ kèo' — không bị đè bởi trạng thái confirmed.
      expect(find.widgetWithText(StampChip, 'Chủ kèo'), findsOneWidget);
      expect(find.byKey(const Key('open_keo_chat_btn')), findsOneWidget);
    },
  );

  testWidgets('header shows time window and area from get_keo_header', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer((_) async => const []);
    when(() => repo.header('k1')).thenAnswer(
      (_) async => const Keo(
        id: 'k1',
        title: 'Hát tối T7',
        areaLabel: 'Hoàn Kiếm, Hà Nội',
        timeWindowStart: '2026-06-30T12:00:00Z',
        timeWindowEnd: '2026-06-30T14:00:00Z',
        status: 'planning',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keoRepositoryProvider.overrideWithValue(repo),
          myProfileProvider.overrideWith((ref) => Future<Profile?>.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('keo_header_time')), findsOneWidget);
    expect(find.byKey(const Key('keo_header_area')), findsOneWidget);
    expect(find.text('Hoàn Kiếm, Hà Nội'), findsOneWidget);
    // Giờ hiển thị theo TZ máy chạy test — kiểm tra động, không hardcode.
    final s = DateTime.parse('2026-06-30T12:00:00Z').toLocal();
    final e = DateTime.parse('2026-06-30T14:00:00Z').toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    expect(
      find.text(
        '${two(s.hour)}:${two(s.minute)} – ${two(e.hour)}:${two(e.minute)}'
        ' · ${s.day}/${s.month}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('free_join_limit error shows the upgrade sheet', (tester) async {
    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer((_) async => const []);
    when(
      () => repo.requestJoin('k1'),
    ).thenThrow('PostgrestException(message: free_join_limit, code: 23514)');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keoRepositoryProvider.overrideWithValue(repo),
          myProfileProvider.overrideWith((ref) => Future<Profile?>.value(null)),
        ],
        child: const MaterialApp(
          home: KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request_join_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Tham gia nhiều kèo cùng lúc'), findsOneWidget);
    expect(find.text('Nâng cấp Pro'), findsOneWidget);
  });
}
