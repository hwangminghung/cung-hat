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
import 'package:cung_hat/features/discovery/presentation/doi_deck_screen.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
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
    'DoiDeckScreen uses the shared EmptyState when no candidates load',
    (tester) async {
      final locationService = _FakeLocationService();
      when(
        () => locationService.captureAndPush(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            candidatesProvider.overrideWith((ref) async => <Candidate>[]),
            locationServiceProvider.overrideWithValue(locationService),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DoiDeckScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Chưa có bạn hát quanh đây'), findsOneWidget);
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
          candidatesProvider.overrideWith(
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
          candidatesProvider.overrideWith(
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

    // Vuốt 1 card để _lastSwiped có giá trị.
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
