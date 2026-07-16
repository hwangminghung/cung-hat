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
import 'package:cung_hat/features/discovery/domain/deck_item.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/doi_deck_screen.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';

Candidate c(String id) => Candidate(id: id);
Keo k(String id, {bool mine = false}) =>
    Keo(id: id, title: 'Kèo $id', isMine: mine);

class _FakeLocationService extends Mock implements LocationService {}

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _FakePhotoRepository extends Mock implements PhotoRepository {
  @override
  Future<List<String>> signedUrlsOf(String userId) async => const [];
}

GoRouter _deckRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DoiDeckScreen()),
        GoRoute(
          path: '/keo/:id',
          builder: (context, state) => Scaffold(
              body: Center(
                  child: Text('KEO DETAIL ${state.pathParameters['id']}'))),
        ),
      ],
    );

void main() {
  test('chèn 1 kèo sau mỗi 5 candidate, tối đa 2, bỏ kèo của mình', () {
    final items = interleaveDeck(
      candidates: [for (var i = 0; i < 12; i++) c('$i')],
      keos: [k('a', mine: true), k('b'), k('c'), k('d')],
    );
    // 12 candidate + 2 promo = 14; promo tại index 5 và 11
    expect(items.length, 14);
    expect(items[5], isA<KeoPromoItem>());
    expect((items[5] as KeoPromoItem).keo.id, 'b'); // 'a' là của mình → bỏ
    expect(items[11], isA<KeoPromoItem>());
    expect((items[11] as KeoPromoItem).keo.id, 'c');
    expect(items.whereType<KeoPromoItem>().length, 2);
  });

  test('deck ngắn hơn 5 hoặc không có kèo → không promo', () {
    expect(
        interleaveDeck(candidates: [c('1'), c('2')], keos: [k('b')])
            .whereType<KeoPromoItem>(),
        isEmpty);
    expect(
        interleaveDeck(
                candidates: [for (var i = 0; i < 8; i++) c('$i')], keos: [])
            .whereType<KeoPromoItem>(),
        isEmpty);
  });

  group('KeoPromoCard trong DoiDeckScreen', () {
    testWidgets('hiện thẻ quảng bá Kèo ở đầu deck', (tester) async {
      final locationService = _FakeLocationService();
      when(() => locationService.captureAndPush())
          .thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            // Promo TRƯỚC candidate: top card là promo, nhưng hasCandidates
            // vẫn true (có 1 CandidateItem) nên deck không rơi vào empty-state.
            deckItemsProvider(null).overrideWith((ref) async => [
                  KeoPromoItem(k('b')),
                  CandidateItem(c('1')),
                ]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _deckRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Kèo gần bạn'), findsOneWidget);
    });

    testWidgets(
        'vuốt phải thẻ quảng bá → mở KeoDetail, KHÔNG gọi recordSwipe',
        (tester) async {
      final locationService = _FakeLocationService();
      when(() => locationService.captureAndPush())
          .thenAnswer((_) async => LocationCaptureStatus.success);
      final repo = _MockDiscoveryRepository();
      when(() => repo.recordSwipe(any(), any()))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(repo),
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            deckItemsProvider(null).overrideWith((ref) async => [
                  KeoPromoItem(k('b')),
                  CandidateItem(c('1')),
                ]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _deckRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.textContaining('Kèo gần bạn'),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('KEO DETAIL b'), findsOneWidget);
      verifyNever(() => repo.recordSwipe(any(), any()));
    });
  });
}
