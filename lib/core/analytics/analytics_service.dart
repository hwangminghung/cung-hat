import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Telemetry P0-3 — bọc Firebase Analytics sau MỘT điểm gửi duy nhất [log].
/// NO-OP an toàn khi Firebase chưa init (local thiếu google-services.json,
/// cùng gate ngoài với FCM): telemetry không bao giờ được phá flow chính nên
/// mọi method nuốt lỗi, không throw. Đọc Firebase.apps LAZY mỗi lần log để
/// tự "bật" khi _initPush init Firebase xong — không phụ thuộc thứ tự boot.
class AnalyticsService {
  static const _firstSwipeKey = 'analytics_first_swipe_sent';

  FirebaseAnalytics? get _analytics {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  /// Điểm gửi duy nhất — test override chỗ này để ghi lại event.
  @visibleForTesting
  Future<void> log(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('analytics: skip $name: $e');
    }
  }

  Future<void> logLogin() => log('login');

  /// Kích hoạt thật = hoàn tất onboarding (profile được tạo).
  Future<void> logSignUp() => log('sign_up');

  /// [stepNumber] 1-based theo UI "Bước x/4".
  Future<void> logOnboardingStep(int stepNumber) =>
      log('onboarding_step_$stepNumber');

  /// granted = quyền vị trí không bị từ chối (GPS tắt/no-fix vẫn tính granted
  /// — spec đo kết quả XIN QUYỀN, không đo chất lượng fix).
  Future<void> logLocationResult({required bool granted}) =>
      log(granted ? 'location_granted' : 'location_denied');

  Future<void> logMatch() => log('match');

  Future<void> logKeoJoinRequest() => log('keo_join_request');

  Future<void> logChatSent(String threadType) =>
      log('chat_sent', {'thread_type': threadType});

  /// Metric TTFV — chỉ log MỘT lần mỗi thiết bị, cờ persist qua prefs.
  Future<void> logFirstSwipe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_firstSwipeKey) ?? false) return;
      await prefs.setBool(_firstSwipeKey, true);
    } catch (_) {
      // Không đọc/ghi được cờ → thà bỏ event còn hơn spam sai metric.
      return;
    }
    await log('first_swipe');
  }
}

final analyticsProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);
