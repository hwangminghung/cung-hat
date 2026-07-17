import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/doi_deck_screen.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';
import '../../support/supabase_mocks.dart';

class _FakeLocationService extends Mock implements LocationService {}

class _FakePhotoRepository extends Mock implements PhotoRepository {
  @override
  Future<List<String>> signedUrlsOf(String userId) async => const [];
}

void main() {
  test('getCandidates truyền p_radius_km', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_discovery_candidates', params: {
          'p_limit': 20,
          'p_radius_km': 100,
          'p_genre': null,
        })).thenAnswer((_) => rpcOk(<dynamic>[]));
    final repo = DiscoveryRepository(client);
    final res = await repo.getCandidates(radiusKm: 100);
    expect(res, isEmpty);
    verify(() => client.rpc('get_discovery_candidates', params: {
          'p_limit': 20,
          'p_radius_km': 100,
          'p_genre': null,
        })).called(1);
  });

  test('get/setAutoExpand gọi đúng RPC', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_discovery_auto_expand'))
        .thenAnswer((_) => rpcOk(true));
    when(() => client.rpc('set_discovery_auto_expand',
            params: {'p_on': true}))
        .thenAnswer((_) => rpcOk(null));
    final repo = DiscoveryRepository(client);
    expect(await repo.getAutoExpand(), isTrue);
    await repo.setAutoExpand(true);
    verify(() => client.rpc('set_discovery_auto_expand',
        params: {'p_on': true})).called(1);
  });

  group('getDiscoveryPrefs', () {
    test('map hoá composite row (auto_expand, radius_km)', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('get_discovery_prefs')).thenAnswer(
          (_) => rpcOk({'auto_expand': true, 'radius_km': 80}));
      final result = await DiscoveryRepository(client).getDiscoveryPrefs();
      expect(result.autoExpand, isTrue);
      expect(result.radiusKm, 80);
    });

    test('unwrap List-shaped result (setof-style)', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('get_discovery_prefs')).thenAnswer((_) => rpcOk([
            {'auto_expand': false, 'radius_km': 50},
          ]));
      final result = await DiscoveryRepository(client).getDiscoveryPrefs();
      expect(result.autoExpand, isFalse);
      expect(result.radiusKm, 50);
    });

    test('radius_km null → mặc định 50, auto_expand thiếu → false', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('get_discovery_prefs'))
          .thenAnswer((_) => rpcOk(<String, dynamic>{}));
      final result = await DiscoveryRepository(client).getDiscoveryPrefs();
      expect(result.autoExpand, isFalse);
      expect(result.radiusKm, 50);
    });
  });

  test('setDiscoveryRadius gọi đúng RPC set_discovery_radius', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('set_discovery_radius', params: {'p_km': 80}))
        .thenAnswer((_) => rpcOk(null));
    await DiscoveryRepository(client).setDiscoveryRadius(80);
    verify(() => client.rpc('set_discovery_radius', params: {'p_km': 80}))
        .called(1);
  });

  group('empty-deck expand UI', () {
    testWidgets(
        'deck rỗng hiện nút mở rộng + switch tự mở rộng (autoExpand=false)',
        (tester) async {
      final locationService = _FakeLocationService();
      when(() => locationService.captureAndPush())
          .thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            candidatesProvider(null).overrideWith((ref) async => <Candidate>[]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50)),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expand_radius_btn')), findsOneWidget);
      expect(find.byKey(const Key('auto_expand_switch')), findsOneWidget);
      expect(find.text('Chưa có bạn hát quanh đây'), findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('auto_expand_switch')),
      );
      expect(switchTile.value, isFalse);
    });

    testWidgets('bấm mở rộng → deckRadiusProvider chuyển sang 100',
        (tester) async {
      final locationService = _FakeLocationService();
      when(() => locationService.captureAndPush())
          .thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            candidatesProvider(null).overrideWith((ref) async => <Candidate>[]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50)),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DoiDeckScreen)),
      );
      // Chưa bấm mở rộng: override phiên vẫn null (dùng bán kính server 50).
      expect(container.read(deckRadiusProvider), isNull);

      await tester.tap(find.byKey(const Key('expand_radius_btn')));
      await tester.pump();

      expect(container.read(deckRadiusProvider), 100);
    });

    testWidgets('bật switch tự mở rộng → gọi setAutoExpand trên repository',
        (tester) async {
      final locationService = _FakeLocationService();
      when(() => locationService.captureAndPush())
          .thenAnswer((_) async => LocationCaptureStatus.success);
      final repo = _MockDiscoveryRepositoryForRadius();
      when(() => repo.setAutoExpand(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(repo),
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            candidatesProvider(null).overrideWith((ref) async => <Candidate>[]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50)),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auto_expand_switch')));
      await tester.pumpAndSettle();

      verify(() => repo.setAutoExpand(true)).called(1);
    });

    testWidgets('setAutoExpand lỗi → SnackBar báo lỗi, không crash',
        (tester) async {
      final locationService = _FakeLocationService();
      when(() => locationService.captureAndPush())
          .thenAnswer((_) async => LocationCaptureStatus.success);
      // RPC lỗi async (offline/server) — UI phải nuốt lỗi + báo SnackBar,
      // KHÔNG leak unhandled exception, KHÔNG invalidate discoveryPrefsProvider.
      final repo = _MockDiscoveryRepositoryForRadius();
      when(() => repo.setAutoExpand(any()))
          .thenAnswer((_) async => throw Exception('offline'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(repo),
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            candidatesProvider(null).overrideWith((ref) async => <Candidate>[]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50)),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auto_expand_switch')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Không lưu được cài đặt, thử lại.'), findsOneWidget);
      // Switch giữ nguyên off — lưu thất bại thì không invalidate provider.
      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('auto_expand_switch')),
      );
      expect(switchTile.value, isFalse);
    });

    testWidgets(
        'radius=100 & deck vẫn rỗng → hiện "Đã tìm hết trong 100 km" + nút Làm mới',
        (tester) async {
      final locationService = _FakeLocationService();
      when(() => locationService.captureAndPush())
          .thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            candidatesProvider(null).overrideWith((ref) async => <Candidate>[]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50)),
            deckRadiusProvider.overrideWith((ref) => 100),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã tìm hết trong 100 km'), findsOneWidget);
      expect(find.byKey(const Key('deck_retry_btn')), findsOneWidget);
      expect(find.byKey(const Key('expand_radius_btn')), findsNothing);
      // Vòng cuối UI review: header (kèm radius_chip) giờ LUÔN hiện — kể cả
      // khi deck rỗng — nên chip phạm vi 100 km vẫn còn trên đầu màn.
      expect(find.byKey(const Key('radius_chip')), findsOneWidget);
    });

    testWidgets('deck CÓ candidate + radius=100 → header hiện radius_chip',
        (tester) async {
      final locationService = _FakeLocationService();
      when(() => locationService.captureAndPush())
          .thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            candidatesProvider(null).overrideWith((ref) async => const [
                  Candidate(id: 'c1', displayName: 'A'),
                ]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50)),
            deckRadiusProvider.overrideWith((ref) => 100),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('radius_chip')), findsOneWidget);
      expect(find.text('Đang tìm trong 100 km'), findsOneWidget);
    });

    testWidgets(
        'radius=50 rỗng + autoExpand=true → tự động chuyển sang 100 (postframe)',
        (tester) async {
      final locationService = _FakeLocationService();
      when(() => locationService.captureAndPush())
          .thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
            candidatesProvider(null).overrideWith((ref) async => <Candidate>[]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: true, radiusKm: 50)),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DoiDeckScreen)),
      );
      expect(container.read(deckRadiusProvider), 100);
    });
  });
}

class _MockDiscoveryRepositoryForRadius extends Mock
    implements DiscoveryRepository {}
