import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/router.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

void main() {
  test('unauthenticated is sent to /auth', () {
    expect(
      authRedirect(signedIn: false, hasProfile: false, location: '/'),
      '/auth',
    );
  });
  test('signed-in without profile goes to /onboarding', () {
    expect(
      authRedirect(signedIn: true, hasProfile: false, location: '/'),
      '/onboarding',
    );
  });
  test('signed-in with profile on /auth goes home', () {
    expect(
      authRedirect(signedIn: true, hasProfile: true, location: '/auth'),
      '/',
    );
  });
  test('signed-in with profile on /otp goes home', () {
    expect(
      authRedirect(signedIn: true, hasProfile: true, location: '/otp'),
      '/',
    );
  });
  test('signed-in with profile leaves /onboarding for home', () {
    expect(
      authRedirect(signedIn: true, hasProfile: true, location: '/onboarding'),
      '/',
    );
  });
  test('signed-in with profile elsewhere is not redirected', () {
    expect(
      authRedirect(signedIn: true, hasProfile: true, location: '/'),
      isNull,
    );
  });
  test('bước ảnh sau onboarding (P1-6) KHÔNG bị đá về home', () {
    // /onboarding/photos chạy SAU khi profile đã tạo — redirect chỉ match
    // đúng chuỗi '/onboarding', route con phải được ở lại.
    expect(
      authRedirect(
        signedIn: true,
        hasProfile: true,
        location: '/onboarding/photos',
      ),
      isNull,
    );
  });
  test('unauthenticated can view a shared plan', () {
    expect(
      authRedirect(
        signedIn: false,
        hasProfile: false,
        location: '/plan/shared/tok',
      ),
      isNull,
    );
  });
  test('unauthenticated can view a shared keo', () {
    expect(
      authRedirect(
        signedIn: false,
        hasProfile: false,
        location: '/keo/shared/tok',
      ),
      isNull,
    );
  });

  // Profile chưa load xong (null = unknown): đứng yên chờ, KHÔNG được đoán
  // /onboarding — tránh flash màn onboarding cho user đã có hồ sơ (bug OTP kẹt).
  test('signed-in with profile still loading holds position on /otp', () {
    expect(
      authRedirect(signedIn: true, hasProfile: null, location: '/otp'),
      isNull,
    );
  });
  test('signed-in with profile still loading holds position on /', () {
    expect(
      authRedirect(signedIn: true, hasProfile: null, location: '/'),
      isNull,
    );
  });
  test(
    'signed-in with profile still loading holds position on /onboarding',
    () {
      expect(
        authRedirect(signedIn: true, hasProfile: null, location: '/onboarding'),
        isNull,
      );
    },
  );

  // hasProfileOf: map AsyncValue<Profile?> sang tri-state hasProfile.
  // Bug warm-gate (chip task_7196af60): Riverpod refresh/error GIỮ previous
  // value của TÀI KHOẢN CŨ (copyWithPrevious) — identity cũ không bao giờ
  // được quyết routing sau khi đổi tài khoản.
  group('hasProfileOf', () {
    const oldUser = Profile(id: 'u-old');

    test('loading lần đầu -> null (chờ)', () {
      expect(hasProfileOf(const AsyncLoading<Profile?>()), isNull);
    });
    test('refresh sau đổi tài khoản giữ previous value -> null (không tin '
        'identity cũ)', () async {
      // Dựng state thật qua ProviderContainer: data(oldUser) -> invalidate.
      // Riverpod giữ previous value trong lúc refresh (copyWithPrevious) —
      // chính giả định load-bearing của hasProfileOf.
      final provider = FutureProvider<Profile?>((ref) async => oldUser);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {});
      await container.read(provider.future);

      container.invalidate(provider);
      final refreshing = container.read(provider);

      expect(refreshing.isLoading, isTrue);
      expect(refreshing.hasValue, isTrue, reason: 'previous value phải còn');
      expect(hasProfileOf(refreshing), isNull);
    });
    test('error kèm previous value -> false (không dùng identity cũ)', () async {
      var fail = false;
      // StateError (Error, không phải Exception) để Riverpod không auto-retry.
      final provider = FutureProvider<Profile?>((ref) async {
        if (fail) throw StateError('boom');
        return oldUser;
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {});
      await container.read(provider.future);

      fail = true;
      container.invalidate(provider);
      await expectLater(container.read(provider.future), throwsStateError);
      final errored = container.read(provider);

      expect(errored.hasError, isTrue);
      expect(errored.hasValue, isTrue, reason: 'previous value phải còn');
      expect(hasProfileOf(errored), isFalse);
    });
    test('error không previous -> false', () {
      expect(
        hasProfileOf(AsyncError<Profile?>(StateError('x'), StackTrace.empty)),
        isFalse,
      );
    });
    test('data(null) -> false (chưa có hồ sơ)', () {
      expect(hasProfileOf(const AsyncData<Profile?>(null)), isFalse);
    });
    test('data(profile) -> true', () {
      expect(hasProfileOf(const AsyncData<Profile?>(oldUser)), isTrue);
    });
  });
}
