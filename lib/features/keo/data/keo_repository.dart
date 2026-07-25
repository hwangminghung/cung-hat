import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/keo.dart';
import '../domain/keo_match_suggestion.dart';
import '../domain/keo_member.dart';
import '../domain/shared_keo.dart';

class KeoRepository {
  KeoRepository(this._client);
  final SupabaseClient _client;

  Future<List<Keo>> listOpenKeos({int limit = 30}) async {
    final rows = await _client.rpc(
      'list_open_keos',
      params: {'p_limit': limit},
    );
    return (rows as List)
        .map((e) => Keo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Kèo caller đang dính líu (host / đã duyệt / đang xin vào) cho section
  /// "Kèo của bạn" — lối vào duy nhất khi kèo đã rời trạng thái 'open'.
  Future<List<Keo>> myKeos() async {
    final rows = await _client.rpc('get_my_keos');
    return (rows as List)
        .map((e) => Keo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Header kèo cho màn chi tiết (giờ + khu vực) — null nếu server chặn
  /// (người ngoài với kèo không còn 'open') hoặc kèo không tồn tại.
  Future<Keo?> header(String keoId) async {
    final rows = await _client.rpc('get_keo_header', params: {'p_keo': keoId});
    final list = rows as List;
    if (list.isEmpty) return null;
    return Keo.fromJson(Map<String, dynamic>.from(list.first as Map));
  }

  Future<List<KeoMember>> roster(String keoId) async {
    final rows = await _client.rpc('get_keo_roster', params: {'p_keo': keoId});
    return (rows as List)
        .map((e) => KeoMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<KeoMatchSuggestion>> suggestMatch({int limit = 3}) async {
    final rows = await _client.rpc(
      'suggest_keo_match',
      params: {'p_limit': limit},
    );
    return (rows as List)
        .map(
          (e) =>
              KeoMatchSuggestion.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<String> createKeo({
    required String title,
    required double lat,
    required double lng,
    String? area,
    required DateTime start,
    required DateTime end,
    required int size,
    String? intent,
    String? vibe,
    List<String> genres = const [],
    String joinMode = 'approval',
  }) async {
    final id = await _client.rpc(
      'create_keo',
      params: {
        'p_title': title,
        'p_lat': lat,
        'p_lng': lng,
        'p_area': area,
        'p_start': start.toUtc().toIso8601String(),
        'p_end': end.toUtc().toIso8601String(),
        'p_size': size,
        'p_intent': intent,
        'p_vibe': vibe,
        'p_genres': genres,
        'p_join_mode': joinMode,
      },
    );
    return id as String;
  }

  Future<String> createAutoMatchedKeo({
    required String title,
    required DateTime start,
    required DateTime end,
    required int size,
    List<String> genres = const [],
    String joinMode = 'open',
  }) async {
    final id = await _client.rpc(
      'create_auto_matched_keo',
      params: {
        'p_title': title,
        'p_start': start.toUtc().toIso8601String(),
        'p_end': end.toUtc().toIso8601String(),
        'p_size': size,
        'p_genres': genres,
        'p_join_mode': joinMode,
      },
    );
    return id as String;
  }

  Future<void> requestJoin(String keoId) async {
    await _client.rpc('request_join_keo', params: {'p_keo': keoId});
  }

  Future<void> approve(String keoId, String userId) async {
    await _client.rpc(
      'approve_join',
      params: {'p_keo': keoId, 'p_user': userId},
    );
  }

  Future<void> decline(String keoId, String userId) async {
    await _client.rpc(
      'decline_join',
      params: {'p_keo': keoId, 'p_user': userId},
    );
  }

  Future<void> leave(String keoId) async {
    await _client.rpc('leave_keo', params: {'p_keo': keoId});
  }

  Future<void> confirm(String keoId) async {
    await _client.rpc('confirm_keo', params: {'p_keo': keoId});
  }

  Future<String> createKeoShareLink(String keoId) async {
    final res = await _client.rpc(
      'create_keo_share_link',
      params: {'p_keo': keoId},
    );
    return res as String;
  }

  /// null = token sai/het han-khong-ton-tai/keo da xoa.
  Future<SharedKeo?> resolveSharedKeo(String token) async {
    final res = await _client.rpc(
      'resolve_share_keo',
      params: {'p_token': token},
    );
    if (res == null) return null;
    final m = Map<String, dynamic>.from(
      res is List ? (res.isEmpty ? {} : res.first as Map) : res as Map,
    );
    if (m['keo_id'] == null) return null; // composite rong (token sai)
    return SharedKeo.fromJson(m);
  }
}
