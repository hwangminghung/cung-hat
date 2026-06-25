import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/venue_suggestion.dart';

class Plan {
  Plan({required this.id, required this.keoId, required this.venueId, required this.scheduledAt, required this.status});
  final String id;
  final String keoId;
  final String venueId;
  final String scheduledAt;
  final String status;
  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id: j['id'] as String,
    keoId: j['keo_id'] as String,
    venueId: j['venue_id'] as String,
    scheduledAt: j['scheduled_at'] as String,
    status: (j['status'] ?? 'proposed') as String,
  );
}

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

  Future<Plan?> currentPlan(String keoId) async {
    final row = await _client
        .from('plans').select()
        .eq('keo_id', keoId)
        .order('created_at', ascending: false)
        .limit(1).maybeSingle();
    return row == null ? null : Plan.fromJson(Map<String, dynamic>.from(row));
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

  Future<String> startVenuePayment({
    required String planId, required String venueId,
    required int amountMinor, required String gateway,
  }) async {
    final res = await _client.functions.invoke('create-venue-payment', body: {
      'plan_id': planId, 'venue_id': venueId, 'amount_minor': amountMinor, 'gateway': gateway,
    });
    if (res.status >= 400) {
      throw Exception('create-venue-payment failed (${res.status}): ${res.data}');
    }
    return (res.data as Map)['pay_url'] as String;
  }
}
