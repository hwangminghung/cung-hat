import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/domain/deck_item.dart';
import 'package:cung_hat/features/discovery/domain/music_themes.dart';
import 'package:cung_hat/features/discovery/presentation/doi_deck_screen.dart';
import 'package:cung_hat/features/discovery/presentation/filter_sheet.dart';
import 'package:cung_hat/features/discovery/presentation/theme_board_screen.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';
import '../../support/supabase_mocks.dart';

class _FakeLocationService extends Mock implements LocationService {}

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _FakePhotoRepository extends Mock implements PhotoRepository {
  @override
  Future<List<String>> signedUrlsOf(String userId) async => const [];
}

void main() {
  group('DiscoveryRepository — theme decks', () {
    test('getCandidates gửi p_genre', () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc(
          'get_discovery_candidates',
          params: {'p_limit': 20, 'p_radius_km': 50, 'p_genre': 'ballad'},
        ),
      ).thenAnswer((_) => rpcOk(<dynamic>[]));
      final repo = DiscoveryRepository(client);
      final res = await repo.getCandidates(genre: 'ballad');
      expect(res, isEmpty);
      verify(
        () => client.rpc(
          'get_discovery_candidates',
          params: {'p_limit': 20, 'p_radius_km': 50, 'p_genre': 'ballad'},
        ),
      ).called(1);
    });

    test('getThemeDeckCounts map hoá rows theo genre_id', () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc(
          'get_theme_deck_counts',
          params: {
            'p_genres': ['ballad', 'rap_vn'],
          },
        ),
      ).thenAnswer(
        (_) => rpcOk(<dynamic>[
          {'genre_id': 'ballad', 'live_count': 12},
          {'genre_id': 'rap_vn', 'live_count': 0},
        ]),
      );
      final repo = DiscoveryRepository(client);
      final res = await repo.getThemeDeckCounts(['ballad', 'rap_vn']);
      expect(res, {'ballad': 12, 'rap_vn': 0});
    });

    test('getThemeDeckCounts: live_count null → 0', () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc(
          'get_theme_deck_counts',
          params: {
            'p_genres': ['bolero'],
          },
        ),
      ).thenAnswer(
        (_) => rpcOk(<dynamic>[
          {'genre_id': 'bolero', 'live_count': null},
        ]),
      );
      final repo = DiscoveryRepository(client);
      final res = await repo.getThemeDeckCounts(['bolero']);
      expect(res, {'bolero': 0});
    });
  });

  group('DoiDeckScreen — GPS capture chỉ chạy ở deck chính', () {
    testWidgets(
      'genre != null → KHÔNG gọi captureAndPush (dùng lại vị trí đã lưu)',
      (tester) async {
        final locationService = _FakeLocationService();
        when(
          () => locationService.captureAndPush(),
        ).thenAnswer((_) async => LocationCaptureStatus.success);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
              deckItemsProvider('ballad').overrideWith(
                (ref) async => [
                  const CandidateItem(Candidate(id: 'c1', displayName: 'A')),
                ],
              ),
              locationServiceProvider.overrideWithValue(locationService),
              entitlementsProvider.overrideWith((ref) async => <String>{}),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const DoiDeckScreen(genre: 'ballad'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        verifyNever(() => locationService.captureAndPush());
      },
    );

    testWidgets('genre == null (deck chính) → gọi captureAndPush đúng 1 lần', (
      tester,
    ) async {
      final locationService = _FakeLocationService();
      when(
        () => locationService.captureAndPush(),
      ).thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            deckItemsProvider(null).overrideWith(
              (ref) async => [
                const CandidateItem(Candidate(id: 'c1', displayName: 'A')),
              ],
            ),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DoiDeckScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => locationService.captureAndPush()).called(1);
    });
  });

  group('ThemeBoardScreen', () {
    GoRouter boardRouter() => GoRouter(
      initialLocation: '/explore',
      routes: [
        GoRoute(path: '/explore', builder: (_, _) => const ThemeBoardScreen()),
        GoRoute(
          path: '/explore/:genre',
          builder: (_, s) => Scaffold(
            body: Center(
              child: Text('GENRE DECK ${s.pathParameters['genre']}'),
            ),
          ),
        ),
      ],
    );

    testWidgets(
      'hiện tên chủ đề + số người đang hát từ themeDeckCountsProvider',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              themeDeckCountsProvider.overrideWith(
                (ref) async => {
                  'ballad': 12,
                  'rap_vn': 3,
                  'bolero': 0,
                  'kpop': 1,
                  'vpop': 7,
                },
              ),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: boardRouter(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('screen_10_explore_themes')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('theme_card_ballad')), findsOneWidget);
        expect(find.byKey(const Key('theme_brand_plaque')), findsOneWidget);
        expect(find.text('Đêm Ballad'), findsOneWidget);
        expect(find.text('12 người đang hát'), findsOneWidget);
      },
    );

    testWidgets('Bolero 0 hiện Đang mở + board có plaque CÙNG HÁT', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeDeckCountsProvider.overrideWith(
              (ref) async => {
                'ballad': 12,
                'rap_vn': 3,
                'bolero': 0,
                'kpop': 1,
                'vpop': 7,
              },
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: boardRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đang mở'), findsOneWidget);
      expect(find.text('0 người đang hát'), findsNothing);
      expect(find.text('CÙNG HÁT'), findsOneWidget);
    });

    testWidgets('bấm thẻ chủ đề → điều hướng sang deck genre đó', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeDeckCountsProvider.overrideWith(
              (ref) async => {
                'ballad': 12,
                'rap_vn': 3,
                'bolero': 0,
                'kpop': 1,
                'vpop': 7,
              },
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: boardRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('theme_card_ballad')));
      await tester.pumpAndSettle();

      expect(find.text('GENRE DECK ballad'), findsOneWidget);
    });

    testWidgets(
      'board stays responsive across required widths and text scales',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (final width in const [360.0, 393.0, 430.0]) {
          for (final scale in const [1.0, 1.2, 1.4]) {
            await tester.binding.setSurfaceSize(Size(width, 844));
            final platform = width == 393 && scale == 1.4
                ? TargetPlatform.iOS
                : TargetPlatform.android;
            final router = boardRouter();

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  themeDeckCountsProvider.overrideWith(
                    (ref) async => {
                      'ballad': 12,
                      'rap_vn': 3,
                      'bolero': 0,
                      'kpop': 1,
                      'vpop': 7,
                    },
                  ),
                ],
                child: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 844),
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: MaterialApp.router(
                    theme: AppTheme.light().copyWith(platform: platform),
                    routerConfig: router,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: '${width}dp ×$scale on $platform',
            );
            expect(
              find.byKey(const Key('screen_10_explore_themes')),
              findsOneWidget,
            );
            expect(find.byKey(const Key('theme_card_ballad')), findsOneWidget);
            expect(find.byKey(const Key('theme_brand_plaque')), findsOneWidget);

            await tester.pumpWidget(const SizedBox.shrink());
            router.dispose();
          }
        }
      },
    );
  });

  group('DoiDeckScreen — genre mode header', () {
    testWidgets(
      'genre != null → tiêu đề theo MusicTheme, ẩn explore/boost, có nút back',
      (tester) async {
        final locationService = _FakeLocationService();
        when(
          () => locationService.captureAndPush(),
        ).thenAnswer((_) async => LocationCaptureStatus.success);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
              deckItemsProvider('ballad').overrideWith(
                (ref) async => [
                  const CandidateItem(Candidate(id: 'c1', displayName: 'A')),
                ],
              ),
              locationServiceProvider.overrideWithValue(locationService),
              entitlementsProvider.overrideWith((ref) async => <String>{}),
              discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const DoiDeckScreen(genre: 'ballad'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(musicThemeById('ballad')!.title), findsOneWidget);
        expect(find.byKey(const Key('explore_btn')), findsNothing);
        expect(find.byKey(const Key('deck_boost_btn')), findsNothing);
        expect(find.byKey(const Key('filter_btn')), findsNothing);
        expect(find.byKey(const Key('theme_deck_back')), findsOneWidget);
      },
    );

    testWidgets(
      'genre == null (deck chính) → có nút explore + boost + filter',
      (tester) async {
        final locationService = _FakeLocationService();
        when(
          () => locationService.captureAndPush(),
        ).thenAnswer((_) async => LocationCaptureStatus.success);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
              deckItemsProvider(null).overrideWith(
                (ref) async => [
                  const CandidateItem(Candidate(id: 'c1', displayName: 'A')),
                ],
              ),
              locationServiceProvider.overrideWithValue(locationService),
              entitlementsProvider.overrideWith((ref) async => <String>{}),
              discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const DoiDeckScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('explore_btn')), findsOneWidget);
        expect(find.byKey(const Key('deck_boost_btn')), findsOneWidget);
        expect(find.byKey(const Key('filter_btn')), findsOneWidget);
        expect(find.byKey(const Key('theme_deck_back')), findsNothing);
      },
    );

    testWidgets('bấm filter_btn (deck chính) → mở FilterSheet', (tester) async {
      final locationService = _FakeLocationService();
      when(
        () => locationService.captureAndPush(),
      ).thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            deckItemsProvider(null).overrideWith(
              (ref) async => [
                const CandidateItem(Candidate(id: 'c1', displayName: 'A')),
              ],
            ),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
              (ref) async => (autoExpand: false, radiusKm: 50),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DoiDeckScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(FilterSheet), findsOneWidget);
    });
  });

  group('DoiDeckScreen — deck chủ đề RỖNG vẫn có nút back', () {
    testWidgets(
      'genre deck rỗng → theme_deck_back + expand_radius_btn cùng hiện; bấm back → pop về board',
      (tester) async {
        final locationService = _FakeLocationService();
        when(
          () => locationService.captureAndPush(),
        ).thenAnswer((_) async => LocationCaptureStatus.success);

        // Harness router mirror app router (router.dart): /explore/:genre dựng
        // DoiDeckScreen THẬT — pop phải quan sát được qua nội dung route dưới.
        final router = GoRouter(
          initialLocation: '/explore',
          routes: [
            GoRoute(
              path: '/explore',
              builder: (_, _) =>
                  const Scaffold(body: Center(child: Text('BOARD'))),
            ),
            GoRoute(
              path: '/explore/:genre',
              builder: (_, s) =>
                  DoiDeckScreen(genre: s.pathParameters['genre']),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
              deckItemsProvider(
                'ballad',
              ).overrideWith((ref) async => <DeckItem>[]),
              locationServiceProvider.overrideWithValue(locationService),
              entitlementsProvider.overrideWith((ref) async => <String>{}),
              discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50),
              ),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        router.push('/explore/ballad');
        await tester.pumpAndSettle();

        // Deck rỗng: empty state hiện NHƯNG vẫn phải có lối quay lại in-app.
        expect(find.byKey(const Key('theme_deck_back')), findsOneWidget);
        expect(find.byKey(const Key('expand_radius_btn')), findsOneWidget);
        expect(find.text(musicThemeById('ballad')!.title), findsOneWidget);

        await tester.tap(find.byKey(const Key('theme_deck_back')));
        await tester.pumpAndSettle();

        expect(find.text('BOARD'), findsOneWidget);
        expect(find.byKey(const Key('theme_deck_back')), findsNothing);
      },
    );

    testWidgets('main deck rỗng (genre == null) → KHÔNG có theme_deck_back', (
      tester,
    ) async {
      final locationService = _FakeLocationService();
      when(
        () => locationService.captureAndPush(),
      ).thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            deckItemsProvider(null).overrideWith((ref) async => <DeckItem>[]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
              (ref) async => (autoExpand: false, radiusKm: 50),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DoiDeckScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expand_radius_btn')), findsOneWidget);
      expect(find.byKey(const Key('theme_deck_back')), findsNothing);
    });
  });

  group('Neo rewind xuyên deck (lastSwipeAnchorProvider)', () {
    Future<void> pumpMainDeck(
      WidgetTester tester, {
      required DiscoveryRepository repo,
    }) async {
      final locationService = _FakeLocationService();
      when(
        () => locationService.captureAndPush(),
      ).thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(repo),
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            deckItemsProvider(null).overrideWith(
              (ref) async => const [
                CandidateItem(Candidate(id: 'x1', displayName: 'X1')),
                CandidateItem(Candidate(id: 'x2', displayName: 'X2')),
              ],
            ),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{'pro'}),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DoiDeckScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'neo thuộc deck KHÁC → rewind trên main deck no-op, KHÔNG gọi undo_last_swipe',
      (tester) async {
        final repo = _MockDiscoveryRepository();
        when(
          () => repo.recordSwipe(any(), any()),
        ).thenAnswer((_) async => false);
        when(() => repo.undoLastSwipe()).thenAnswer((_) async => true);

        await pumpMainDeck(tester, repo: repo);

        // Vuốt X1 trên main deck — neo rewind trỏ vào deck chính.
        await tester.tap(find.byKey(const Key('deck_like_btn')));
        await tester.pumpAndSettle();

        // Mô phỏng: user push /explore/ballad (main deck vẫn mounted phía dưới)
        // và vuốt Y ở đó — swipe THẬT mới nhất phía server giờ thuộc deck
        // ballad, không phải main. undo_last_swipe là GLOBAL: gọi từ main deck
        // lúc này sẽ xoá nhầm swipe Y của deck ballad trong khi UI main khôi
        // phục X1 — chính là desync mà neo toàn cục phải chặn.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(DoiDeckScreen)),
        );
        container.read(lastSwipeAnchorProvider.notifier).state = (
          genre: 'ballad',
          candidate: const Candidate(id: 'y', displayName: 'Y'),
        );

        await tester.tap(find.byKey(const Key('deck_rewind_btn')));
        await tester.pumpAndSettle();

        verifyNever(() => repo.undoLastSwipe());
      },
    );

    testWidgets(
      'neo thuộc ĐÚNG deck → rewind vẫn gọi undo_last_swipe bình thường',
      (tester) async {
        final repo = _MockDiscoveryRepository();
        when(
          () => repo.recordSwipe(any(), any()),
        ).thenAnswer((_) async => false);
        final pendingUndo = Completer<bool>();
        when(() => repo.undoLastSwipe()).thenAnswer((_) => pendingUndo.future);

        await pumpMainDeck(tester, repo: repo);

        // Vuốt X1 trên main deck → neo = (genre: null, candidate: X1), khớp
        // deck đang đứng.
        await tester.tap(find.byKey(const Key('deck_like_btn')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('deck_rewind_btn')));
        await tester.pump();

        verify(() => repo.undoLastSwipe()).called(1);

        pendingUndo.complete(true);
        await tester.pumpAndSettle();

        // Card X1 được khôi phục về deck (controller.undo thành công).
        expect(find.text('X1'), findsOneWidget);
      },
    );
  });
}
