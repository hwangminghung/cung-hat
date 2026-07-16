import 'package:cung_hat/core/analytics/analytics_service.dart';

/// Fake ghi lại event cho test P0-3 — override điểm gửi duy nhất [log] nên
/// mọi ngữ nghĩa helper (map tên event, cờ first_swipe) vẫn chạy thật.
class RecordingAnalytics extends AnalyticsService {
  final events = <String>[];
  final params = <Map<String, Object>?>[];

  @override
  Future<void> log(String name, [Map<String, Object>? parameters]) async {
    events.add(name);
    params.add(parameters);
  }
}
