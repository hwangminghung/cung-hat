import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/discovery_repository.dart';
import '../domain/candidate.dart';

final discoveryRepositoryProvider =
    Provider((ref) => DiscoveryRepository(ref.watch(supabaseClientProvider)));
final candidatesProvider = FutureProvider<List<Candidate>>(
    (ref) => ref.watch(discoveryRepositoryProvider).getCandidates());
