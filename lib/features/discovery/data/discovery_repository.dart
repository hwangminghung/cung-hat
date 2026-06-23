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
}
