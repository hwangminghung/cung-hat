import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';

class _MockPhotoRepository extends Mock implements PhotoRepository {}

void main() {
  // Regression guard for BUG-2 ROOT CAUSE: the edge mints signed URLs that
  // expire in minutes, so `signedUrlsProvider` MUST be autoDispose — it must
  // drop its cached batch once nothing watches it and RE-MINT on the next
  // listen. When it was a plain (kept-alive) FutureProvider, re-opening a detail
  // sheet replayed the first, now-expired batch; the carousel's 2nd photo (whose
  // Image.network only fires on swipe) then loaded an expired token, 400'd, and
  // fell back to the monogram. This test fails if the provider goes back to
  // caching across listen cycles.
  test('signedUrlsProvider re-mints after its listeners drop (autoDispose)',
      () async {
    final repo = _MockPhotoRepository();
    var mint = 0;
    // Each call hands back a fresh, distinct batch — mirrors the real edge whose
    // short-lived tokens differ per mint. A kept-alive provider would only ever
    // call this once and replay the first batch.
    when(() => repo.signedUrlsOf('user-9')).thenAnswer((_) async {
      mint++;
      return ['https://signed/mint-$mint/0', 'https://signed/mint-$mint/1'];
    });

    final container = ProviderContainer(
      overrides: [photoRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    // First open: mint batch #1.
    final sub1 = container.listen(
      signedUrlsProvider('user-9'),
      (_, next) {},
      fireImmediately: true,
    );
    final first = await container.read(signedUrlsProvider('user-9').future);
    expect(first, ['https://signed/mint-1/0', 'https://signed/mint-1/1']);

    // Sheet closes → last listener gone → autoDispose drops the cache.
    sub1.close();
    await Future<void>.delayed(Duration.zero); // let the autoDispose run

    // Second open: must RE-MINT (fresh, distinct URLs), not replay batch #1.
    container.listen(
      signedUrlsProvider('user-9'),
      (_, next) {},
      fireImmediately: true,
    );
    final second = await container.read(signedUrlsProvider('user-9').future);
    expect(second, ['https://signed/mint-2/0', 'https://signed/mint-2/1']);
    verify(() => repo.signedUrlsOf('user-9')).called(2);
  });
}
