import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/discovery_repository.dart';
import '../domain/candidate.dart';
import 'location_service.dart';

final discoveryRepositoryProvider =
    Provider((ref) => DiscoveryRepository(ref.watch(supabaseClientProvider)));
final locationServiceProvider =
    Provider((ref) => LocationService(ref.watch(discoveryRepositoryProvider)));
final candidatesProvider = FutureProvider<List<Candidate>>(
    (ref) => ref.watch(discoveryRepositoryProvider).getCandidates());
final whoLikedMeProvider = FutureProvider<List<Candidate>>(
    (ref) => ref.watch(discoveryRepositoryProvider).whoLikedMe());

/// Thời điểm hết hạn của lượt Boost đang chạy; null khi không boost.
final activeBoostProvider = StateProvider<DateTime?>((ref) => null);
