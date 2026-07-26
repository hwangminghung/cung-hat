import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/push/push_messaging.dart';
import 'package:cung_hat/core/push/push_registrar.dart';
import 'package:cung_hat/core/push/push_service.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

class _MockPushService extends Mock implements PushService {}

/// Fake thật (không mock) — kiểm chứng hành vi, không kiểm chứng cách gọi.
class _FakeMessaging implements PushMessaging {
  bool granted = true;
  String? token = 'tok-1';
  int permissionRequests = 0;
  final _refresh = StreamController<String>.broadcast();

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  void emitRefreshedToken(String t) => _refresh.add(t);
  Future<void> close() => _refresh.close();
}

void main() {
  late _MockPushService service;
  late _FakeMessaging messaging;

  setUp(() {
    service = _MockPushService();
    messaging = _FakeMessaging();
    when(() => service.registerToken(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() => messaging.close());

  // [AUDIT P1-3] Trước đây token bị bỏ im lặng khi chưa có session và KHÔNG
  // bao giờ đăng ký lại — user cài mới, cấp quyền, rồi đăng nhập thì token
  // không bao giờ tới server: mọi push (kể cả 2 cron nhắc kèo) rơi vào hư vô.
  test('đăng ký token khi user đã đăng nhập', () async {
    await PushRegistrar(messaging, service).registerForSignedInUser();
    verify(() => service.registerToken('tok-1', any())).called(1);
  });

  test('user từ chối quyền → không đăng ký token', () async {
    messaging.granted = false;
    await PushRegistrar(messaging, service).registerForSignedInUser();
    verifyNever(() => service.registerToken(any(), any()));
  });

  test('token null (FCM chưa cấp) → không gọi RPC', () async {
    messaging.token = null;
    await PushRegistrar(messaging, service).registerForSignedInUser();
    verifyNever(() => service.registerToken(any(), any()));
  });

  test('token refresh sau khi đăng nhập → đăng ký lại', () async {
    final registrar = PushRegistrar(messaging, service);
    addTearDown(registrar.dispose);
    await registrar.registerForSignedInUser();

    messaging.emitRefreshedToken('tok-2');
    await pumpEventQueue();

    verify(() => service.registerToken('tok-2', any())).called(1);
  });

  test(
    'gọi nhiều lần chỉ xin quyền một lần, không nhân đôi listener',
    () async {
      final registrar = PushRegistrar(messaging, service);
      addTearDown(registrar.dispose);
      await registrar.registerForSignedInUser();
      await registrar.registerForSignedInUser();

      expect(messaging.permissionRequests, 1);
      messaging.emitRefreshedToken('tok-2');
      await pumpEventQueue();
      verify(() => service.registerToken('tok-2', any())).called(1);
    },
  );

  test(
    'lỗi RPC không ném ra ngoài (không được làm hỏng luồng vào app)',
    () async {
      when(
        () => service.registerToken(any(), any()),
      ).thenThrow(StateError('net'));
      await expectLater(
        PushRegistrar(messaging, service).registerForSignedInUser(),
        completes,
      );
    },
  );

  // Điểm kích hoạt: user CÓ hồ sơ = đã đăng nhập và đã qua onboarding, tức
  // đang ở trong app — không phải lúc cold start ở màn đăng nhập.
  group('pushRegistrationProvider', () {
    ProviderContainer containerFor(AsyncValue<Profile?> profile) {
      final container = ProviderContainer(
        overrides: [
          myProfileProvider.overrideWith((ref) async => profile.value),
          pushRegistrarProvider.overrideWithValue(
            PushRegistrar(messaging, service),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('chưa có hồ sơ → chưa xin quyền', () async {
      final container = containerFor(const AsyncData<Profile?>(null));
      container.listen(pushRegistrationProvider, (_, _) {});
      await pumpEventQueue();
      expect(messaging.permissionRequests, 0);
    });

    test('hồ sơ xuất hiện → đăng ký token', () async {
      final container = containerFor(
        const AsyncData<Profile?>(Profile(id: 'u1')),
      );
      container.listen(pushRegistrationProvider, (_, _) {});
      await pumpEventQueue();
      verify(() => service.registerToken('tok-1', any())).called(1);
    });
  });
}
