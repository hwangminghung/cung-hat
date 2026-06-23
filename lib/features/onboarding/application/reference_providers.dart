import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/reference_repository.dart';
import '../domain/music_ref.dart';

final referenceRepositoryProvider =
    Provider((ref) => ReferenceRepository(ref.watch(supabaseClientProvider)));
final genresProvider = FutureProvider<List<Genre>>((ref) => ref.watch(referenceRepositoryProvider).genres());
final artistsProvider = FutureProvider<List<Artist>>((ref) => ref.watch(referenceRepositoryProvider).artists());
final songsProvider = FutureProvider<List<Song>>((ref) => ref.watch(referenceRepositoryProvider).songs());
