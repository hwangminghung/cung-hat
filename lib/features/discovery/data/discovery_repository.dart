import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/candidate.dart';
import '../domain/like_teaser.dart';

class DiscoveryRepository {
  DiscoveryRepository(this._client);
  final SupabaseClient _client;

  Future<List<Candidate>> getCandidates(
      {int limit = 20, int radiusKm = 50, String? genre}) async {
    final rows = await _client.rpc('get_discovery_candidates', params: {
      'p_limit': limit,
      'p_radius_km': radiusKm,
      'p_genre': genre,
    });
    return (rows as List)
        .map((e) => Candidate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Đếm người active-7-ngày quanh 50km theo từng genre (cho board Khám Phá).
  Future<Map<String, int>> getThemeDeckCounts(List<String> genreIds) async {
    final rows = await _client
        .rpc('get_theme_deck_counts', params: {'p_genres': genreIds});
    return {
      for (final r in (rows as List))
        (r as Map)['genre_id'] as String: (r['live_count'] as int?) ?? 0,
    };
  }

  /// Đọc pref "tự mở rộng bán kính khi hết deck" đã lưu server-side.
  Future<bool> getAutoExpand() async =>
      await _client.rpc('get_discovery_auto_expand') == true;

  /// Lưu pref "tự mở rộng bán kính khi hết deck" server-side.
  Future<void> setAutoExpand(bool on) async {
    await _client.rpc('set_discovery_auto_expand', params: {'p_on': on});
  }

  /// (auto_expand, radius_km) — nguồn chính cho Bộ lọc.
  Future<({bool autoExpand, int radiusKm})> getDiscoveryPrefs() async {
    final res = await _client.rpc('get_discovery_prefs');
    final m = Map<String, dynamic>.from(
        res is List ? (res.isEmpty ? {} : res.first as Map) : res as Map);
    return (
      autoExpand: m['auto_expand'] == true,
      radiusKm: (m['radius_km'] as num?)?.toInt() ?? 50,
    );
  }

  /// Lưu bán kính tìm kiếm (km, 5-100) server-side qua Bộ lọc.
  Future<void> setDiscoveryRadius(int km) async {
    await _client.rpc('set_discovery_radius', params: {'p_km': km});
  }

  /// Users who have liked the current user. Server raises `entitlement_required`
  /// (surfaced as an error) when the caller lacks the `see_likes` entitlement.
  Future<List<Candidate>> whoLikedMe() async {
    final rows = await _client.rpc('who_liked_me');
    return (rows as List)
        .map((e) => Candidate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Returns true if a mutual match was created.
  Future<bool> recordSwipe(String targetId, String direction) async {
    final res = await _client.rpc('record_swipe',
        params: {'p_target': targetId, 'p_direction': direction});
    return res == true;
  }

  Future<void> updateMyLocation(double lat, double lng, {String? area}) async {
    await _client.rpc('update_my_location',
        params: {'p_lat': lat, 'p_lng': lng, 'p_area': area});
  }

  Future<void> reportUser(String targetId, String reason) async {
    await _client.rpc('report_user', params: {'p_target': targetId, 'p_reason': reason});
  }

  Future<void> blockUser(String targetId) async {
    await _client.rpc('block_user', params: {'p_blocked': targetId});
  }

  /// Rút lại lượt vuốt gần nhất (Pro). Server raise `pro_required` nếu free.
  Future<bool> undoLastSwipe() async {
    final res = await _client.rpc('undo_last_swipe');
    return res == true;
  }

  /// Kích hoạt Boost 30 phút (Pro). Trả về thời điểm hết hạn. Server raise
  /// pro_required / boost_active / boost_limit nếu không đủ điều kiện.
  Future<DateTime> activateBoost() async {
    final res = await _client.rpc('activate_boost');
    return DateTime.parse(res as String);
  }

  /// Match id đang active với [otherId], null nếu chưa match.
  Future<String?> getMatchIdWith(String otherId) async {
    final res =
        await _client.rpc('get_match_id_with', params: {'p_other': otherId});
    return res as String?;
  }

  /// Hồ sơ người ĐÃ match (icebreaker trong chat). null = RPC không trả gì,
  /// hoặc đối phương đã xoá tài khoản (composite null-row, id null).
  Future<Candidate?> getMatchProfile(String matchId) async {
    final res =
        await _client.rpc('get_match_profile', params: {'p_match': matchId});
    if (res == null) return null;
    final m = Map<String, dynamic>.from(
        res is List ? (res.isEmpty ? {} : res.first as Map) : res as Map);
    if (m['id'] == null) return null; // composite null-row (đối phương xoá mem)
    return Candidate.fromJson(m);
  }

  /// Teaser cho user free — danh sách người thích mình đã làm mờ (edge
  /// `likes-teaser`): KHÔNG id/tên; ảnh là bản mosaic server-side, không bao
  /// giờ là ảnh gốc. Rebase origin như sign-photo (kong:8000 local).
  Future<List<LikeTeaser>> getLikesTeaser() async {
    final res = await _client.functions.invoke('likes-teaser');
    final list = (res.data?['likers'] as List?) ?? const [];
    final base = Uri.parse(_client.storage.url);
    return [
      for (final e in list)
        LikeTeaser.fromJson(Map<String, dynamic>.from(e as Map)).rebase(base),
    ];
  }
}
