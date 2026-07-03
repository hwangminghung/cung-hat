import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/candidate.dart';

class DiscoveryRepository {
  DiscoveryRepository(this._client);
  final SupabaseClient _client;

  Future<List<Candidate>> getCandidates({int limit = 20}) async {
    final rows = await _client.rpc('get_discovery_candidates', params: {'p_limit': limit});
    return (rows as List)
        .map((e) => Candidate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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

  /// Match id đang active với [otherId], null nếu chưa match.
  Future<String?> getMatchIdWith(String otherId) async {
    final res =
        await _client.rpc('get_match_id_with', params: {'p_other': otherId});
    return res as String?;
  }
}
