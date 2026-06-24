import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/venue_suggestion.dart';

class PlanRepository {
  PlanRepository(this._client);
  final SupabaseClient _client;

  Future<List<VenueSuggestion>> nearestVenues(String keoId, {int limit = 5}) async {
    final rows = await _client.rpc('nearest_venues_for_keo',
        params: {'p_keo': keoId, 'p_limit': limit});
    return (rows as List)
        .map((e) => VenueSuggestion.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> proposePlan(String keoId, String venueId, DateTime when) async {
    final id = await _client.rpc('propose_keo_plan', params: {
      'p_keo': keoId,
      'p_venue': venueId,
      'p_when': when.toUtc().toIso8601String(),
    });
    return id as String;
  }

  Future<void> confirmPlan(String planId) async {
    await _client.rpc('confirm_keo_plan', params: {'p_plan': planId});
  }

  Future<void> checkInArrived(String planId) async {
    await _client.rpc('checkin_arrived', params: {'p_plan': planId});
  }

  Future<String> createShareLink(String planId) async {
    final tok = await _client.rpc('create_share_link', params: {'p_plan': planId});
    return tok as String;
  }
}
