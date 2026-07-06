import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../keo/application/keo_providers.dart';
import '../../keo/domain/keo.dart';
import '../data/discovery_repository.dart';
import '../domain/candidate.dart';
import '../domain/deck_item.dart';
import '../domain/music_themes.dart';
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

/// [genre] null = deck chính (không lọc); khác null = deck chủ đề Khám Phá
/// (mục 9 Tinder-parity), lọc ứng viên theo đúng genre đó phía server.
final candidatesProvider =
    FutureProvider.family<List<Candidate>, String?>((ref, genre) => ref
        .watch(discoveryRepositoryProvider)
        .getCandidates(radiusKm: ref.watch(deckRadiusProvider), genre: genre));
final whoLikedMeProvider = FutureProvider<List<Candidate>>(
    (ref) => ref.watch(discoveryRepositoryProvider).whoLikedMe());

/// Deck Đôi trộn ứng viên thật với thẻ quảng bá Kèo (mục 13 Tinder-parity).
/// Kèo lỗi/chưa tải không được chặn deck chính — nuốt lỗi, coi như rỗng.
/// [genre] theo family của candidatesProvider ở trên.
final deckItemsProvider =
    FutureProvider.family<List<DeckItem>, String?>((ref, genre) async {
  final candidates = await ref.watch(candidatesProvider(genre).future);
  List<Keo> keos = const [];
  if (genre == null) {
    // Promo Kèo chỉ trộn ở deck chính — deck chủ đề giữ thuần ứng viên.
    try {
      keos = await ref.watch(openKeosProvider.future);
    } catch (_) {}
  }
  return interleaveDeck(candidates: candidates, keos: keos);
});

/// Số người "live" (active 7 ngày, quanh 50km) mỗi chủ đề nhạc — cho board
/// Khám Phá (ThemeBoardScreen).
final themeDeckCountsProvider = FutureProvider<Map<String, int>>((ref) => ref
    .watch(discoveryRepositoryProvider)
    .getThemeDeckCounts([for (final t in musicThemes) t.genreId]));

/// Thời điểm hết hạn của lượt Boost đang chạy; null khi không boost.
final activeBoostProvider = StateProvider<DateTime?>((ref) => null);

/// Neo rewind toàn cục: swipe THẬT gần nhất trên bất kỳ deck nào (main/genre).
/// undo_last_swipe phía server là GLOBAL nên rewind chỉ hợp lệ khi neo thuộc
/// đúng deck đang bấm — neo lệch deck mà vẫn undo là desync client/server.
final lastSwipeAnchorProvider =
    StateProvider<({String? genre, Candidate candidate})?>((ref) => null);
