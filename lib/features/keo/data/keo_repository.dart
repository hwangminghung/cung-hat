import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/keo.dart';
import '../domain/keo_match_suggestion.dart';
import '../domain/keo_member.dart';

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

  Future<List<KeoMember>> roster(String keoId) async {
    final rows = await _client.rpc('get_keo_roster', params: {'p_keo': keoId});
    return (rows as List)
        .map((e) => KeoMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Keo> getKeoDetail(String keoId) async {
    final row = await _client.rpc('get_keo_detail', params: {'p_keo': keoId});
    return Keo.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<void> applyBoost(String keoId) async {
    await _client.rpc('apply_keo_boost', params: {'p_keo': keoId});
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
}
