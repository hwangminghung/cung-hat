import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/keo_repository.dart';
import '../domain/keo.dart';
import '../domain/keo_match_suggestion.dart';
import '../domain/keo_member.dart';
import '../domain/shared_keo.dart';

final keoRepositoryProvider = Provider(
  (ref) => KeoRepository(ref.watch(supabaseClientProvider)),
);

final openKeosProvider = FutureProvider<List<Keo>>(
  (ref) => ref.watch(keoRepositoryProvider).listOpenKeos(),
);

final keoMatchSuggestionsProvider =
    FutureProvider.autoDispose<List<KeoMatchSuggestion>>(
      (ref) => ref.watch(keoRepositoryProvider).suggestMatch(),
    );

final keoRosterProvider = FutureProvider.family<List<KeoMember>, String>(
  (ref, keoId) => ref.watch(keoRepositoryProvider).roster(keoId),
);

final keoHeaderProvider = FutureProvider.family<Keo?, String>(
  (ref, keoId) => ref.watch(keoRepositoryProvider).header(keoId),
);

final myKeosProvider = FutureProvider<List<Keo>>(
  (ref) => ref.watch(keoRepositoryProvider).myKeos(),
);

final sharedKeoProvider = FutureProvider.family<SharedKeo?, String>(
  (ref, token) => ref.watch(keoRepositoryProvider).resolveSharedKeo(token),
);
