import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../keo/application/keo_providers.dart';
import '../../keo/domain/keo.dart';
import '../data/discovery_repository.dart';
import '../domain/candidate.dart';
import '../domain/deck_item.dart';
import '../domain/like_teaser.dart';
import '../domain/music_themes.dart';
import 'location_service.dart';

final discoveryRepositoryProvider = Provider(
  (ref) => DiscoveryRepository(ref.watch(supabaseClientProvider)),
);
final locationServiceProvider = Provider(
  (ref) => LocationService(ref.watch(discoveryRepositoryProvider)),
);

/// Kết quả lần captureAndPush GẦN NHẤT (P0-1) — null = chưa thử lần nào.
/// Deck Đôi ghi khi vào tab; board Kèo đọc chung (list_open_keos cũng cần vị
/// trí đã lưu) nên cả hai màn phân biệt được "thiếu vị trí" với "hết người".
final locationStatusProvider = StateProvider<LocationCaptureStatus?>(
  (ref) => null,
);

/// (auto_expand, radius_km) đã lưu server-side — nguồn chính cho Bộ lọc và
/// cho bán kính hiệu lực của deck (xem [candidatesProvider]).
final discoveryPrefsProvider =
    FutureProvider<({bool autoExpand, int radiusKm})>(
      (ref) => ref.watch(discoveryRepositoryProvider).getDiscoveryPrefs(),
    );

/// Override PHIÊN (session) cho bán kính — one-shot "mở rộng 100km" khi deck
/// rỗng. null = dùng bán kính đã lưu server ([discoveryPrefsProvider]); khác
/// null = ghi đè tạm cho phiên app hiện tại, KHÔNG lưu server, reset khi user
/// lưu bộ lọc mới (FilterSheet null hoá lại override này sau khi Áp dụng).
final deckRadiusProvider = StateProvider<int?>((ref) => null);

/// [genre] null = deck chính (không lọc); khác null = deck chủ đề Khám Phá
/// (mục 9 Tinder-parity), lọc ứng viên theo đúng genre đó phía server.
/// Bán kính hiệu lực: override phiên ([deckRadiusProvider]) nếu có, nếu
/// không thì bán kính đã lưu server ([discoveryPrefsProvider]); lỗi đọc pref
/// (offline/RPC) nuốt về mặc định 50 — không được chặn deck chỉ vì bộ lọc
/// chưa tải xong.
final candidatesProvider = FutureProvider.family<List<Candidate>, String?>((
  ref,
  genre,
) async {
  final override = ref.watch(deckRadiusProvider);
  int radius;
  try {
    radius =
        override ?? (await ref.watch(discoveryPrefsProvider.future)).radiusKm;
  } catch (_) {
    radius = override ?? 50;
  }
  return ref
      .watch(discoveryRepositoryProvider)
      .getCandidates(radiusKm: radius, genre: genre);
});
final whoLikedMeProvider = FutureProvider<List<Candidate>>(
  (ref) => ref.watch(discoveryRepositoryProvider).whoLikedMe(),
);

/// Teaser "Ai thích bạn" cho user free — bản mosaic server-side, không id/tên.
final likesTeaserProvider = FutureProvider<List<LikeTeaser>>(
  (ref) => ref.watch(discoveryRepositoryProvider).getLikesTeaser(),
);

/// Deck Đôi trộn ứng viên thật với thẻ quảng bá Kèo (mục 13 Tinder-parity).
/// Kèo lỗi/chưa tải không được chặn deck chính — nuốt lỗi, coi như rỗng.
/// [genre] theo family của candidatesProvider ở trên.
final deckItemsProvider = FutureProvider.family<List<DeckItem>, String?>((
  ref,
  genre,
) async {
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
final themeDeckCountsProvider = FutureProvider<Map<String, int>>(
  (ref) => ref.watch(discoveryRepositoryProvider).getThemeDeckCounts([
    for (final t in musicThemes) t.genreId,
  ]),
);

/// Thời điểm hết hạn của lượt Boost đang chạy; null khi không boost.
final activeBoostProvider = StateProvider<DateTime?>((ref) => null);

/// Neo rewind toàn cục: swipe THẬT gần nhất trên bất kỳ deck nào (main/genre).
/// undo_last_swipe phía server là GLOBAL nên rewind chỉ hợp lệ khi neo thuộc
/// đúng deck đang bấm — neo lệch deck mà vẫn undo là desync client/server.
final lastSwipeAnchorProvider =
    StateProvider<({String? genre, Candidate candidate})?>((ref) => null);
