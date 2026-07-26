import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supabase_providers.dart';
import '../../features/profile/application/profile_providers.dart';
import 'push_messaging.dart';
import 'push_service.dart';

/// Gắn token FCM của thiết bị vào tài khoản đang đăng nhập.
///
/// [AUDIT P1-3] Bản cũ chạy trong `main()`: xin quyền ngay khi mở app (lúc
/// user còn chưa biết app là gì) rồi BỎ IM LẶNG token nếu chưa có session, và
/// chỉ đăng ký lại khi FCM xoay token. Hệ quả: user cài mới → cấp quyền →
/// đăng nhập thì token KHÔNG BAO GIỜ được đăng ký, mọi push (kể cả hai cron
/// nhắc kèo) rơi vào hư vô cho tới lần xoay token ngẫu nhiên nào đó.
class PushRegistrar {
  PushRegistrar(this._messaging, this._service);

  final PushMessaging _messaging;
  final PushService _service;
  StreamSubscription<String>? _refreshSub;
  bool _asked = false;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// Gọi khi user đã đăng nhập VÀ đã có hồ sơ — tức đang ở trong app, không
  /// phải lúc cold start ở màn đăng nhập. Idempotent: chỉ hỏi quyền một lần
  /// và chỉ gắn một listener token-refresh.
  ///
  /// Không bao giờ ném: hỏng đăng ký push không được chặn đường vào app.
  Future<void> registerForSignedInUser() async {
    if (_asked) return;
    _asked = true;
    try {
      if (!await _messaging.requestPermission()) return;
      // Gắn listener TRƯỚC khi await token: nếu FCM xoay token ngay sau đó,
      // không bỏ sót lần xoay đầu tiên.
      _refreshSub ??= _messaging.onTokenRefresh.listen(_register);
      await _register(await _messaging.getToken());
    } catch (e) {
      debugPrint('Push register skipped: $e');
    }
  }

  Future<void> _register(String? token) async {
    if (token == null) return;
    try {
      await _service.registerToken(token, _platform);
    } catch (e) {
      debugPrint('Push token register failed: $e');
    }
  }

  Future<void> dispose() async {
    final sub = _refreshSub;
    _refreshSub = null;
    await sub?.cancel();
  }
}

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => FirebasePushMessaging(FirebaseMessaging.instance),
);

final pushServiceProvider = Provider(
  (ref) => PushService(ref.watch(supabaseClientProvider)),
);

final pushRegistrarProvider = Provider((ref) {
  final registrar = PushRegistrar(
    ref.watch(pushMessagingProvider),
    ref.watch(pushServiceProvider),
  );
  ref.onDispose(registrar.dispose);
  return registrar;
});

/// Side-effect provider: watch ở tầng app để việc đăng ký push xảy ra ĐÚNG
/// lúc user có hồ sơ (đăng nhập xong + qua onboarding), và xảy ra lại sau khi
/// đổi tài khoản.
final pushRegistrationProvider = Provider<void>((ref) {
  if (ref.watch(myProfileProvider).value == null) return;
  unawaited(ref.read(pushRegistrarProvider).registerForSignedInUser());
});
