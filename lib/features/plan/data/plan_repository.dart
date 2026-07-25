import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/venue_suggestion.dart';

class Plan {
  Plan({
    required this.id,
    required this.keoId,
    required this.venueId,
    required this.scheduledAt,
    required this.status,
  });
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

/// Diem giua nhom da duoc server tinh va snap (~110m). KHONG phai vi tri thanh vien.
class MapPoint {
  const MapPoint({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

class PlanRepository {
  PlanRepository(this._client);
  final SupabaseClient _client;

  Future<List<VenueSuggestion>> nearestVenues(
    String keoId, {
    int limit = 5,
  }) async {
    final rows = await _client.rpc(
      'nearest_venues_for_keo',
      params: {'p_keo': keoId, 'p_limit': limit},
    );
    return (rows as List)
        .map((e) => VenueSuggestion.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MapPoint?> getKeoMidpoint(String keoId) async {
    final rows =
        await _client.rpc('get_keo_midpoint', params: {'p_keo': keoId})
            as List<dynamic>;
    if (rows.isEmpty) return null;
    final m = rows.first as Map<String, dynamic>;
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return MapPoint(lat: lat, lng: lng);
  }

  Future<String> proposePlan(
    String keoId,
    String venueId,
    DateTime when,
  ) async {
    final id = await _client.rpc(
      'propose_keo_plan',
      params: {
        'p_keo': keoId,
        'p_venue': venueId,
        'p_when': when.toUtc().toIso8601String(),
      },
    );
    return id as String;
  }

  Future<Plan?> currentPlan(String keoId) async {
    final row = await _client
        .from('plans')
        .select()
        .eq('keo_id', keoId)
        // [DEBT] Khong loc thi sau khi huy, ban 'cancelled' van la ban moi
        // nhat -> man Ke hoach hien ke hoach da huy thay vi danh sach quan.
        .neq('status', 'cancelled')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Plan.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> confirmPlan(String planId) async {
    await _client.rpc('confirm_keo_plan', params: {'p_plan': planId});
  }

  /// Host huy plan proposed/confirmed. Server (cancel_keo_plan) tra keo
  /// 'confirmed' ve 'planning' de chot lai quan/gio.
  Future<void> cancelPlan(String planId) async {
    await _client.rpc('cancel_keo_plan', params: {'p_plan': planId});
  }

  /// user_id cua nhung nguoi DA xac nhan plan (policy plan_conf_member_read).
  /// Ten hien thi lay tu roster keo phia caller — bang nay chi co id.
  Future<Set<String>> planConfirmations(String planId) async {
    final rows = await _client
        .from('plan_confirmations')
        .select('user_id')
        .eq('plan_id', planId);
    return {
      for (final r in (rows as List))
        (r as Map<String, dynamic>)['user_id'] as String,
    };
  }

  Future<void> checkInArrived(String planId) async {
    await _client.rpc('checkin_arrived', params: {'p_plan': planId});
  }

  Future<String> createShareLink(String planId) async {
    final tok = await _client.rpc(
      'create_share_link',
      params: {'p_plan': planId},
    );
    return tok as String;
  }

  Future<Map<String, dynamic>> resolveShare(String token) async {
    final res = await _client.rpc(
      'resolve_share_plan',
      params: {'p_token': token},
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<String> startVenuePayment({
    required String planId,
    required String venueId,
    required String gateway,
  }) async {
    final res = await _client.functions.invoke(
      'create-venue-payment',
      body: {'plan_id': planId, 'venue_id': venueId, 'gateway': gateway},
    );
    if (res.status >= 400) {
      throw Exception(
        'create-venue-payment failed (${res.status}): ${res.data}',
      );
    }
    return (res.data as Map)['pay_url'] as String;
  }
}
