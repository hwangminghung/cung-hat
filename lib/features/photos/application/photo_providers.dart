import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../data/photo_repository.dart';

final photoRepositoryProvider = Provider(
  (ref) => PhotoRepository(ref.watch(supabaseClientProvider)),
);

/// The current user's photo paths, derived from [myProfileProvider]. Empty while
/// the profile is loading or has no photos.
final myPhotoPathsProvider = Provider<List<String>>(
  (ref) => ref.watch(myProfileProvider).value?.photoPaths ?? const [],
);

/// Short-lived signed URLs for [userId]'s photos (empty if none/blocked).
///
/// `autoDispose`: the edge mints URLs that expire quickly, so the result MUST
/// NOT be cached past the moment it stops being watched. Without this, closing
/// then re-opening a detail sheet (or scrolling a card off-screen and back)
/// replays the first batch of now-expired URLs, and any lazily-built page — e.g.
/// the 2nd carousel photo, whose `Image.network` only fires on swipe — loads an
/// expired token and 400s into the monogram fallback. Dropping the cache when
/// unwatched forces a fresh mint on the next open. `invalidate` (see
/// `photo_manager_sheet`) still works to refresh in place after up/delete.
final signedUrlsProvider =
    FutureProvider.autoDispose.family<List<String>, String>(
  (ref, userId) => ref.watch(photoRepositoryProvider).signedUrlsOf(userId),
);
