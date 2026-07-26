import 'package:firebase_messaging/firebase_messaging.dart';

/// Cổng mỏng lên FCM.
///
/// Tồn tại để [PushRegistrar] test được: FirebaseMessaging đi qua platform
/// channel nên không dựng được trong unit test.
abstract class PushMessaging {
  /// Hỏi quyền nhận thông báo. Trả true khi user ĐỒNG Ý.
  Future<bool> requestPermission();

  /// Token thiết bị hiện tại, null khi FCM chưa cấp được.
  Future<String?> getToken();

  /// FCM xoay token theo chu kỳ — mỗi lần xoay phải đăng ký lại.
  Stream<String> get onTokenRefresh;
}

class FirebasePushMessaging implements PushMessaging {
  const FirebasePushMessaging();

  /// Đọc LAZY, không giữ sẵn instance.
  ///
  /// Thiếu google-services.json thì `FirebaseMessaging.instance` ném
  /// `[core/no-app]`. Nếu chạm nó lúc dựng provider, exception rơi ra ngoài
  /// mọi try/catch và hạ cả app xuống red screen. Đọc trong từng method thì
  /// lỗi rơi đúng vào try/catch của PushRegistrar.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    final status = settings.authorizationStatus;
    // provisional = quyền im lặng của iOS: vẫn gửi được, vẫn phải đăng ký.
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
