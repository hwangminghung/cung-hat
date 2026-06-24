import 'package:supabase_flutter/supabase_flutter.dart';

class Report {
  Report({required this.id, required this.targetType, required this.targetId, this.reason, required this.status});
  final String id;
  final String targetType;
  final String targetId;
  final String? reason;
  final String status;
  factory Report.fromJson(Map<String, dynamic> j) => Report(
    id: j['id'] as String,
    targetType: j['target_type'] as String,
    targetId: j['target_id'] as String,
    reason: j['reason'] as String?,
    status: j['status'] as String,
  );
}

class ModerationRepository {
  ModerationRepository(this._client);
  final SupabaseClient _client;

  Future<List<Report>> listReports({String status = 'open'}) async {
    final rows = await _client.rpc('admin_list_reports', params: {'p_status': status});
    return (rows as List).map((e) => Report.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> action(String reportId, String action, {String? reason}) async {
    await _client.rpc('admin_action_report',
        params: {'p_report': reportId, 'p_action': action, 'p_reason': reason});
  }
}
