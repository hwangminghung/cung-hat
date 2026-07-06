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
import 'package:cung_hat/features/keo/presentation/keo_board_screen.dart';

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
  Future<bool> captureAndPush() async => true;

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

Keo _openKeo({String id = 'open-1', String title = 'Open keo'}) =>
    Keo(id: id, title: title, sizeTarget: 4, slotsFilled: 1, joinMode: 'open');

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
  testWidgets('FREE user: tapping Tao keo shows the upgrade sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MaterialApp(theme: AppTheme.light(), home: const KeoBoardScreen()),
        entitlements: const <String>{},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo kèo'));
    await tester.pumpAndSettle();

    expect(find.text('Tự tạo kèo của riêng bạn'), findsOneWidget);
    expect(find.text('Nâng cấp Pro'), findsOneWidget);
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

    // The FAB reads isProProvider, which depends on the async entitlements
    // future. Nothing in this isolated screen keeps that future alive, so warm
    // it (as a parent shell would in the real app) before tapping.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(KeoBoardScreen)),
    );
    await container.read(entitlementsProvider.future);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo kèo'));
    await tester.pumpAndSettle();

    expect(find.text('Tự tạo kèo của riêng bạn'), findsNothing);
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
}
