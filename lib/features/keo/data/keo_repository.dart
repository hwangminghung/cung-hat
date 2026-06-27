import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/keo.dart';
import '../domain/keo_member.dart';

class KeoRepository {
  KeoRepository(this._client);
  final SupabaseClient _client;

  Future<List<Keo>> listOpenKeos({int limit = 30}) async {
    final rows = await _client.rpc('list_open_keos', params: {'p_limit': limit});
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
    final id = await _client.rpc('create_keo', params: {
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
    });
    return id as String;
  }

  Future<void> requestJoin(String keoId) async {
    await _client.rpc('request_join_keo', params: {'p_keo': keoId});
  }

  Future<void> approve(String keoId, String userId) async {
    await _client
        .rpc('approve_join', params: {'p_keo': keoId, 'p_user': userId});
  }

  Future<void> decline(String keoId, String userId) async {
    await _client
        .rpc('decline_join', params: {'p_keo': keoId, 'p_user': userId});
  }

  Future<void> leave(String keoId) async {
    await _client.rpc('leave_keo', params: {'p_keo': keoId});
  }

  Future<void> confirm(String keoId) async {
    await _client.rpc('confirm_keo', params: {'p_keo': keoId});
  }
}
