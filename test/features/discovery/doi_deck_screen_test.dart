import 'dart:async';

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
import 'package:cung_hat/features/discovery/presentation/candidate_card.dart';
import 'package:cung_hat/features/discovery/presentation/doi_deck_screen.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';
import 'package:cung_hat/shared/widgets/pro_upsell_sheet.dart';

class _FakeLocationService extends Mock implements LocationService {}

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

/// Cards embed PhotoCarousel → signedUrlsProvider → photoRepositoryProvider →
/// Supabase. This fake returns no photos so every card degrades to the monogram
/// fallback without touching the uninitialized Supabase client.
class _FakePhotoRepository extends Mock implements PhotoRepository {
  @override
  Future<List<String>> signedUrlsOf(String userId) async => const [];
}

void main() {
  testWidgets(
    'DoiDeckScreen shows the radius-expand empty state when no candidates load',
    (tester) async {
      final locationService = _FakeLocationService();
      when(
        () => locationService.captureAndPush(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            candidatesProvider(null).overrideWith((ref) async => <Candidate>[]),
            locationServiceProvider.overrideWithValue(locationService),
            entitlementsProvider.overrideWith((ref) async => <String>{}),
            discoveryPrefsProvider.overrideWith(
                (ref) async => (autoExpand: false, radiusKm: 50)),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DoiDeckScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Empty-deck (radius=50, chưa hết 100km) hiện nút mở rộng + switch tự
      // mở rộng thay vì EmptyState/'Làm mới gợi ý' cũ (Tinder-parity mục 2).
      expect(find.text('Chưa có bạn hát quanh đây'), findsOneWidget);
      expect(find.byKey(const Key('expand_radius_btn')), findsOneWidget);
      expect(find.byKey(const Key('auto_expand_switch')), findsOneWidget);
    },
  );

  testWidgets('like_limit lỗi dồn dập chỉ mở một ProUpsellSheet', (
    tester,
  ) async {
    final locationService = _FakeLocationService();
    when(
      () => locationService.captureAndPush(),
    ).thenAnswer((_) async => false);

    // recordSwipe trả future treo để dồn 2 lỗi like_limit về cùng lúc,
    // mô phỏng user vuốt nhanh khi đã hết lượt.
    final repo = _MockDiscoveryRepository();
    final pendingSwipes = <Completer<bool>>[];
    when(() => repo.recordSwipe(any(), any())).thenAnswer((_) {
      final completer = Completer<bool>();
      pendingSwipes.add(completer);
      return completer.future;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(repo),
          photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
          candidatesProvider(null).overrideWith(
            (ref) async => const [
              Candidate(id: 'c1', displayName: 'A'),
              Candidate(id: 'c2', displayName: 'B'),
            ],
          ),
          locationServiceProvider.overrideWithValue(locationService),
          entitlementsProvider.overrideWith((ref) async => <String>{}),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deck_like_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deck_like_btn')));
    await tester.pumpAndSettle();

    expect(pendingSwipes, hasLength(2));
    for (final swipe in pendingSwipes) {
      swipe.completeError(Exception('like_limit'));
    }
    await tester.pumpAndSettle();

    expect(find.byType(ProUpsellSheet), findsOneWidget);
    expect(find.text('Hết lượt thích hôm nay'), findsOneWidget);
  });

  testWidgets('swipe bị từ chối like_limit → card được hoàn về deck', (
    tester,
  ) async {
    final locationService = _FakeLocationService();
    when(
      () => locationService.captureAndPush(),
    ).thenAnswer((_) async => false);

    // recordSwipe raise like_limit — server chưa ghi lượt vuốt, nên client
    // phải undo để card quay lại deck. Dùng completer để lỗi về SAU khi
    // CardSwiper đã ghi swipe vào history (giống test like_limit dồn dập).
    final repo = _MockDiscoveryRepository();
    final pending = Completer<bool>();
    when(
      () => repo.recordSwipe(any(), any()),
    ).thenAnswer((_) => pending.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(repo),
          photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
          candidatesProvider(null).overrideWith(
            (ref) async => const [
              Candidate(id: 'c1', displayName: 'Quỳnh'),
              Candidate(id: 'c2', displayName: 'Bảo'),
            ],
          ),
          locationServiceProvider.overrideWithValue(locationService),
          entitlementsProvider.overrideWith((ref) async => <String>{}),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Card đầu deck là 'Quỳnh'.
    expect(find.text('Quỳnh'), findsOneWidget);

    // Vuốt phải (like) → onSwipe gán neo rewind (lastSwipeAnchorProvider),
    // gọi _handleSwipe (đang treo).
    await tester.tap(find.byKey(const Key('deck_like_btn')));
    await tester.pumpAndSettle();

    // Bây giờ mới raise like_limit — CardSwiper đã ghi swipe vào history.
    pending.completeError(Exception('like_limit'));
    await tester.pumpAndSettle();

    // Upsell mở vì hết lượt.
    expect(find.byType(ProUpsellSheet), findsOneWidget);

    // Sau _controller.undo(), card 'Quỳnh' bị từ chối phải quay lại deck —
    // front card lại hiển thị (mất undo thì chỉ còn 'Bảo').
    expect(find.byType(CandidateCard), findsWidgets);
    expect(find.text('Quỳnh'), findsOneWidget);
  });

  testWidgets('free bấm boost → mở ProUpsellSheet, không gọi activateBoost', (
    tester,
  ) async {
    final locationService = _FakeLocationService();
    when(
      () => locationService.captureAndPush(),
    ).thenAnswer((_) async => false);

    final repo = _MockDiscoveryRepository();
    when(() => repo.activateBoost()).thenAnswer((_) async => DateTime.now());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(repo),
          photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
          candidatesProvider(null).overrideWith(
            (ref) async => const [
              Candidate(id: 'c1', displayName: 'A'),
              Candidate(id: 'c2', displayName: 'B'),
            ],
          ),
          locationServiceProvider.overrideWithValue(locationService),
          entitlementsProvider.overrideWith((ref) async => <String>{}),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deck_boost_btn')));
    await tester.pump();

    expect(find.byType(ProUpsellSheet), findsOneWidget);
    expect(find.text('Boost hồ sơ của bạn'), findsOneWidget);
    verifyNever(() => repo.activateBoost());
  });

  testWidgets('double-tap boost chỉ gọi activate_boost một lần + hiện SnackBar', (
    tester,
  ) async {
    final locationService = _FakeLocationService();
    when(
      () => locationService.captureAndPush(),
    ).thenAnswer((_) async => false);

    final repo = _MockDiscoveryRepository();
    // activateBoost treo để mô phỏng RPC đang bay khi user bấm boost lần 2.
    final pendingBoost = Completer<DateTime>();
    when(() => repo.activateBoost()).thenAnswer((_) => pendingBoost.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(repo),
          photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
          candidatesProvider(null).overrideWith(
            (ref) async => const [
              Candidate(id: 'c1', displayName: 'A'),
              Candidate(id: 'c2', displayName: 'B'),
            ],
          ),
          locationServiceProvider.overrideWithValue(locationService),
          entitlementsProvider.overrideWith((ref) async => <String>{'pro'}),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deck_boost_btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('deck_boost_btn')));
    await tester.pump();

    verify(() => repo.activateBoost()).called(1);

    pendingBoost.complete(DateTime.now().add(const Duration(minutes: 30)));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Đang boost 30 phút — hồ sơ của bạn được ưu tiên quanh đây.'),
      findsOneWidget,
    );
  });

  testWidgets('tooltip boosting hiện HH:mm giờ ĐỊA PHƯƠNG của expiry', (
    tester,
  ) async {
    final locationService = _FakeLocationService();
    when(
      () => locationService.captureAndPush(),
    ).thenAnswer((_) async => false);

    // Expiry phải là UTC — mô phỏng đúng DateTime.parse('...Z') mà repo trả về
    // từ timestamptz. `expected` tính từ .toLocal() nên đúng ở mọi múi giờ;
    // test này canh gác việc chuyển UTC→local trong _formatHhMm: mã UTC cũ
    // (đọc thẳng .hour/.minute) sẽ FAIL trên máy lệch UTC (vd VN UTC+7).
    final expiry = DateTime.now().toUtc().add(const Duration(minutes: 30));
    final local = expiry.toLocal();
    final expected =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
          candidatesProvider(null).overrideWith(
            (ref) async => const [
              Candidate(id: 'c1', displayName: 'A'),
              Candidate(id: 'c2', displayName: 'B'),
            ],
          ),
          locationServiceProvider.overrideWithValue(locationService),
          entitlementsProvider.overrideWith((ref) async => <String>{'pro'}),
          activeBoostProvider.overrideWith((ref) => expiry),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final boostBtn = tester.widget<IconButton>(
      find.byKey(const Key('deck_boost_btn')),
    );
    expect(boostBtn.tooltip, 'Đang boost đến $expected');
  });

  testWidgets('double-tap rewind chỉ gọi undo_last_swipe một lần', (
    tester,
  ) async {
    final locationService = _FakeLocationService();
    when(
      () => locationService.captureAndPush(),
    ).thenAnswer((_) async => false);

    final repo = _MockDiscoveryRepository();
    when(() => repo.recordSwipe(any(), any())).thenAnswer((_) async => false);
    // undoLastSwipe treo để mô phỏng RPC đang bay khi user bấm rewind lần 2.
    final pendingUndo = Completer<bool>();
    when(() => repo.undoLastSwipe()).thenAnswer((_) => pendingUndo.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(repo),
          photoRepositoryProvider.overrideWithValue(_FakePhotoRepository()),
          candidatesProvider(null).overrideWith(
            (ref) async => const [
              Candidate(id: 'c1', displayName: 'A'),
              Candidate(id: 'c2', displayName: 'B'),
            ],
          ),
          locationServiceProvider.overrideWithValue(locationService),
          entitlementsProvider.overrideWith((ref) async => <String>{'pro'}),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const DoiDeckScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Vuốt 1 card để neo rewind (lastSwipeAnchorProvider) có giá trị.
    await tester.tap(find.byKey(const Key('deck_like_btn')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deck_rewind_btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('deck_rewind_btn')));
    await tester.pump();

    verify(() => repo.undoLastSwipe()).called(1);

    pendingUndo.complete(true);
    await tester.pumpAndSettle();
  });
}
