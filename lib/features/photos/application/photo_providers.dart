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
final signedUrlsProvider = FutureProvider.family<List<String>, String>(
  (ref, userId) => ref.watch(photoRepositoryProvider).signedUrlsOf(userId),
);
