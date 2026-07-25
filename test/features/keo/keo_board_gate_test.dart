import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/domain/keo_match_suggestion.dart';
import 'package:cung_hat/features/keo/domain/keo_member.dart';
import 'package:cung_hat/features/keo/presentation/keo_board_screen.dart';
import 'package:cung_hat/shared/widgets/gradient_button.dart';
import 'package:cung_hat/shared/widgets/ticket_card.dart';

class _FakeKeoRepository implements KeoRepository {
  _FakeKeoRepository({this.suggestions = const [], this.openKeos = const []});

  final List<KeoMatchSuggestion> suggestions;
  final List<Keo> openKeos;
  int joinCalls = 0;
  int createCalls = 0;

  @override
  Future<List<Keo>> listOpenKeos({int limit = 30}) async => openKeos;

  @override
  Future<List<KeoMatchSuggestion>> suggestMatch({int limit = 3}) async =>
      suggestions;

  // Sheet gio fetch roster cho dong "Đang có mặt" — fake tra rong la du.
  @override
  Future<List<KeoMember>> roster(String keoId) async => const [];

  @override
  Future<void> requestJoin(String keoId) async {
    joinCalls++;
  }

  @override
  Future<String> createAutoMatchedKeo({
    required String title,
    required DateTime start,
    required DateTime end,
    required int size,
    List<String> genres = const [],
    String joinMode = 'open',
  }) async {
    createCalls++;
    return 'created-keo';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationService implements LocationService {
  @override
  Future<LocationCaptureStatus> captureAndPush() async =>
      LocationCaptureStatus.success;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderScope _wrap(
  Widget child, {
  required Set<String> entitlements,
  _FakeKeoRepository? repo,
}) {
  return ProviderScope(
    overrides: [
      keoRepositoryProvider.overrideWithValue(repo ?? _FakeKeoRepository()),
      locationServiceProvider.overrideWithValue(_FakeLocationService()),
      entitlementsProvider.overrideWith((ref) async => entitlements),
    ],
    child: child,
  );
}

Keo _openKeo({String id = 'open-1', String title = 'Open keo'}) => Keo(
  id: id,
  title: title,
  sizeTarget: 4,
  slotsFilled: 1,
  memberNames: const ['Minh'],
  joinMode: 'open',
);

GoRouter _boardRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const KeoBoardScreen()),
    GoRoute(
      path: '/keo/create',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('create-stub'))),
    ),
    GoRoute(
      path: '/keo/:id',
      builder: (context, state) =>
          Scaffold(body: Center(child: Text(state.pathParameters['id']!))),
    ),
    GoRoute(
      path: '/store',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('store-stub'))),
    ),
  ],
);

void main() {
  testWidgets('board presents one retro create CTA without a FAB duplicate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MaterialApp(theme: AppTheme.light(), home: const KeoBoardScreen()),
        entitlements: const <String>{'pro'},
        repo: _FakeKeoRepository(openKeos: [_openKeo()]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_11_keo_board')), findsOneWidget);
    expect(find.byType(TicketCard), findsWidgets);
    expect(find.byKey(const Key('keo_member_strip')), findsOneWidget);
    expect(find.text('Tạo kèo'), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('FREE user: bấm Tạo kèo đi thẳng vào màn tạo (P1-5 đảo gate)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _boardRouter(),
        ),
        entitlements: const <String>{},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo kèo'));
    await tester.pumpAndSettle();

    // Gate giờ nằm server-side (free_host_limit khi đã giữ 1 kèo active) —
    // client không chặn trước nữa.
    expect(find.text('Tạo kèo không giới hạn'), findsNothing);
    expect(find.text('create-stub'), findsOneWidget);
  });

  testWidgets('PRO user: tapping Tao keo does NOT show the upgrade sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _boardRouter(),
        ),
        entitlements: const <String>{'pro'},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo kèo'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo kèo không giới hạn'), findsNothing);
    expect(find.text('create-stub'), findsOneWidget);
  });

  testWidgets('banner shows existing keo suggestion and joins it', (
    tester,
  ) async {
    final repo = _FakeKeoRepository(
      openKeos: [_openKeo()],
      suggestions: const [
        KeoMatchSuggestion(
          suggestionType: 'existing_keo',
          keoId: 'match-1',
          title: 'V-Pop toi nay',
          joinMode: 'open',
          reasonLabels: ['shared_genres'],
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _boardRouter(),
        ),
        entitlements: const <String>{'pro'},
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ghép nhóm cho tôi'));
    await tester.pumpAndSettle();

    expect(find.text('Kèo hợp với bạn'), findsOneWidget);

    await tester.tap(find.byKey(const Key('keo_match_join_btn')));
    await tester.pumpAndSettle();

    expect(repo.joinCalls, 1);
    expect(find.text('match-1'), findsOneWidget);
  });

  testWidgets('banner shows proposal suggestion and creates on confirmation', (
    tester,
  ) async {
    final repo = _FakeKeoRepository(
      openKeos: [_openKeo()],
      suggestions: const [
        KeoMatchSuggestion(
          suggestionType: 'new_keo_proposal',
          title: 'V-Pop toi nay',
          proposedStart: '2026-06-30T12:00:00Z',
          proposedEnd: '2026-06-30T15:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _boardRouter(),
        ),
        entitlements: const <String>{'pro'},
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ghép nhóm cho tôi'));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 0);

    await tester.tap(find.byKey(const Key('keo_match_create_btn')));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(find.text('created-keo'), findsOneWidget);
  });

  testWidgets('proposal create errors show a snackbar', (tester) async {
    final repo = _FakeKeoRepository(
      openKeos: [_openKeo()],
      suggestions: const [
        KeoMatchSuggestion(
          suggestionType: 'new_keo_proposal',
          title: 'V-Pop toi nay',
          proposedStart: 'not-a-date',
          proposedEnd: '2026-06-30T15:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _boardRouter(),
        ),
        entitlements: const <String>{'pro'},
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ghép nhóm cho tôi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('keo_match_create_btn')));
    await tester.pump();

    expect(
      find.text('Chưa tìm được kèo phù hợp, thử lại sau.'),
      findsOneWidget,
    );
    expect(repo.createCalls, 0);
  });

  testWidgets('board stays responsive across required widths and text scales', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const keo = Keo(
      id: 'responsive',
      title: 'V-Pop tối nay cùng hội bạn',
      areaLabel: 'Music Box Thủ Đức',
      distanceBand: '1-3',
      timeWindowStart: '2026-07-17T20:00:00',
      timeWindowEnd: '2026-07-17T22:00:00',
      sizeTarget: 5,
      slotsFilled: 3,
      genres: ['V-Pop'],
      memberNames: ['Minh', 'Linh', 'An'],
      hostName: 'Minh',
      joinMode: 'open',
    );

    for (final width in const [360.0, 393.0, 430.0]) {
      for (final scale in const [1.0, 1.2, 1.4]) {
        await tester.binding.setSurfaceSize(Size(width, 844));
        final platform = width == 393 && scale == 1.4
            ? TargetPlatform.iOS
            : TargetPlatform.android;

        await tester.pumpWidget(
          _wrap(
            MediaQuery(
              data: MediaQueryData(
                size: Size(width, 844),
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: MaterialApp(
                theme: AppTheme.light().copyWith(platform: platform),
                home: const KeoBoardScreen(),
              ),
            ),
            entitlements: const <String>{'pro'},
            repo: _FakeKeoRepository(openKeos: const [keo]),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: '${width}dp ×$scale on $platform',
        );
        expect(find.byKey(const Key('screen_11_keo_board')), findsOneWidget);
        expect(find.byType(TicketCard), findsOneWidget);
        expect(find.byKey(const Key('keo_member_strip')), findsOneWidget);
        expect(find.byType(GradientButton), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}
