import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../keo/application/keo_providers.dart';
import '../../keo/domain/keo.dart';
import '../data/discovery_repository.dart';
import '../domain/candidate.dart';
import '../domain/deck_item.dart';
import 'location_service.dart';

final discoveryRepositoryProvider =
    Provider((ref) => DiscoveryRepository(ref.watch(supabaseClientProvider)));
final locationServiceProvider =
    Provider((ref) => LocationService(ref.watch(discoveryRepositoryProvider)));

/// Bán kính deck hiện tại (km). 50 mặc định; 100 khi user mở rộng — reset
/// mỗi phiên app (server chỉ lưu auto_expand, không lưu bán kính).
final deckRadiusProvider = StateProvider<int>((ref) => 50);

final autoExpandProvider = FutureProvider<bool>(
    (ref) => ref.watch(discoveryRepositoryProvider).getAutoExpand());

final candidatesProvider = FutureProvider<List<Candidate>>((ref) => ref
    .watch(discoveryRepositoryProvider)
    .getCandidates(radiusKm: ref.watch(deckRadiusProvider)));
final whoLikedMeProvider = FutureProvider<List<Candidate>>(
    (ref) => ref.watch(discoveryRepositoryProvider).whoLikedMe());

/// Deck Đôi trộn ứng viên thật với thẻ quảng bá Kèo (mục 13 Tinder-parity).
/// Kèo lỗi/chưa tải không được chặn deck chính — nuốt lỗi, coi như rỗng.
final deckItemsProvider = FutureProvider<List<DeckItem>>((ref) async {
  final candidates = await ref.watch(candidatesProvider.future);
  List<Keo> keos = const [];
  try {
    keos = await ref.watch(openKeosProvider.future);
  } catch (_) {}
  return interleaveDeck(candidates: candidates, keos: keos);
});

/// Thời điểm hết hạn của lượt Boost đang chạy; null khi không boost.
final activeBoostProvider = StateProvider<DateTime?>((ref) => null);
