import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cung_hat/core/analytics/analytics_service.dart';

import '../../support/analytics_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mọi method no-op an toàn khi Firebase chưa init (không throw)', () async {
    final analytics = AnalyticsService();
    await analytics.logLogin();
    await analytics.logSignUp();
    await analytics.logOnboardingStep(2);
    await analytics.logLocationResult(granted: true);
    await analytics.logFirstSwipe();
    await analytics.logMatch();
    await analytics.logKeoJoinRequest();
    await analytics.logChatSent('match');
    // tới đây không throw là pass — telemetry không được phá flow chính
  });

  test('helper map đúng tên event theo spec UX research', () async {
    final rec = RecordingAnalytics();
    await rec.logLogin();
    await rec.logSignUp();
    await rec.logOnboardingStep(3);
    await rec.logLocationResult(granted: true);
    await rec.logLocationResult(granted: false);
    await rec.logMatch();
    await rec.logKeoJoinRequest();
    await rec.logChatSent('keo');

    expect(rec.events, [
      'login',
      'sign_up',
      'onboarding_step_3',
      'location_granted',
      'location_denied',
      'match',
      'keo_join_request',
      'chat_sent',
    ]);
    expect(rec.params.last, {'thread_type': 'keo'});
  });

  test('logFirstSwipe chỉ log MỘT lần mỗi thiết bị (cờ prefs persist)', () async {
    final rec = RecordingAnalytics();
    await rec.logFirstSwipe();
    await rec.logFirstSwipe();
    expect(rec.events, ['first_swipe']);

    // Instance mới (mô phỏng app restart, prefs còn nguyên) vẫn không log lại.
    final rec2 = RecordingAnalytics();
    await rec2.logFirstSwipe();
    expect(rec2.events, isEmpty);
  });
}
