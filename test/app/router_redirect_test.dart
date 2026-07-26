import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/router.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

void main() {
  test('unauthenticated is sent to /auth', () {
    expect(
      authRedirect(signedIn: false, gate: ProfileGate.missing, location: '/'),
      '/auth',
    );
  });
  test('signed-in without profile goes to /onboarding', () {
    expect(
      authRedirect(signedIn: true, gate: ProfileGate.missing, location: '/'),
      '/onboarding',
    );
  });
  test('signed-in with profile on /auth goes home', () {
    expect(
      authRedirect(
        signedIn: true,
        gate: ProfileGate.present,
        location: '/auth',
      ),
      '/',
    );
  });
  test('signed-in with profile on /otp goes home', () {
    expect(
      authRedirect(signedIn: true, gate: ProfileGate.present, location: '/otp'),
      '/',
    );
  });
  test('signed-in with profile leaves /onboarding for home', () {
    expect(
      authRedirect(
        signedIn: true,
        gate: ProfileGate.present,
        location: '/onboarding',
      ),
      '/',
    );
  });
  test('signed-in with profile elsewhere is not redirected', () {
    expect(
      authRedirect(signedIn: true, gate: ProfileGate.present, location: '/'),
      isNull,
    );
  });
  test('bước ảnh sau onboarding (P1-6) KHÔNG bị đá về home', () {
    // /onboarding/photos chạy SAU khi profile đã tạo — redirect chỉ match
    // đúng chuỗi '/onboarding', route con phải được ở lại.
    expect(
      authRedirect(
        signedIn: true,
        gate: ProfileGate.present,
        location: '/onboarding/photos',
      ),
      isNull,
    );
  });
  test('unauthenticated can view a shared plan', () {
    expect(
      authRedirect(
        signedIn: false,
        gate: ProfileGate.missing,
        location: '/plan/shared/tok',
      ),
      isNull,
    );
  });
  test('unauthenticated can view a shared keo', () {
    expect(
      authRedirect(
        signedIn: false,
        gate: ProfileGate.missing,
        location: '/keo/shared/tok',
      ),
      isNull,
    );
  });

  // Profile chưa load xong (loading = unknown): đứng yên chờ, KHÔNG được đoán
  // /onboarding — tránh flash màn onboarding cho user đã có hồ sơ (bug OTP kẹt).
  test('signed-in with profile still loading holds position on /otp', () {
    expect(
      authRedirect(signedIn: true, gate: ProfileGate.loading, location: '/otp'),
      isNull,
    );
  });
  test('signed-in with profile still loading holds position on /', () {
    expect(
      authRedirect(signedIn: true, gate: ProfileGate.loading, location: '/'),
      isNull,
    );
  });
  test(
    'signed-in with profile still loading holds position on /onboarding',
    () {
      expect(
        authRedirect(
          signedIn: true,
          gate: ProfileGate.loading,
          location: '/onboarding',
        ),
        isNull,
      );
    },
  );

  // [AUDIT P1-4] Lỗi TẢI hồ sơ ≠ "chưa có hồ sơ". Trước đây cả hai đều ra
  // /onboarding, nên user cũ mở app lúc mất mạng/server lỗi bị ném vào màn
  // tạo hồ sơ lại. Lỗi phải có màn riêng có nút thử lại — vẫn KHÔNG cho vào
  // deck, vì lúc lỗi giá trị còn lại có thể là của tài khoản trước.
  group('lỗi tải hồ sơ có màn riêng, không đá về onboarding', () {
    test('error → /profile-error chứ không phải /onboarding', () {
      expect(
        authRedirect(signedIn: true, gate: ProfileGate.error, location: '/'),
        '/profile-error',
      );
    });
    test('đang ở /profile-error mà vẫn lỗi → ở lại', () {
      expect(
        authRedirect(
          signedIn: true,
          gate: ProfileGate.error,
          location: '/profile-error',
        ),
        isNull,
      );
    });
    test('thử lại thành công (present) → rời /profile-error về home', () {
      expect(
        authRedirect(
          signedIn: true,
          gate: ProfileGate.present,
          location: '/profile-error',
        ),
        '/',
      );
    });
    test('thử lại xong mới biết chưa có hồ sơ → /onboarding', () {
      expect(
        authRedirect(
          signedIn: true,
          gate: ProfileGate.missing,
          location: '/profile-error',
        ),
        '/onboarding',
      );
    });
    test('/profile-error KHÔNG phải màn công khai: chưa đăng nhập → /auth', () {
      expect(
        authRedirect(
          signedIn: false,
          gate: ProfileGate.error,
          location: '/profile-error',
        ),
        '/auth',
      );
    });
  });

  // profileGateOf: map AsyncValue<Profile?> sang 4 trạng thái.
  // Bug warm-gate (chip task_7196af60): Riverpod refresh/error GIỮ previous
  // value của TÀI KHOẢN CŨ (copyWithPrevious) — identity cũ không bao giờ
  // được quyết routing sau khi đổi tài khoản.
  group('profileGateOf', () {
    const oldUser = Profile(id: 'u-old');

    test('loading lần đầu -> loading (chờ)', () {
      expect(
        profileGateOf(const AsyncLoading<Profile?>()),
        ProfileGate.loading,
      );
    });
    test('refresh sau đổi tài khoản giữ previous value -> loading (không tin '
        'identity cũ)', () async {
      // Dựng state thật qua ProviderContainer: data(oldUser) -> invalidate.
      // Riverpod giữ previous value trong lúc refresh (copyWithPrevious) —
      // chính giả định load-bearing của profileGateOf.
      final provider = FutureProvider<Profile?>((ref) async => oldUser);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {});
      await container.read(provider.future);

      container.invalidate(provider);
      final refreshing = container.read(provider);

      expect(refreshing.isLoading, isTrue);
      expect(refreshing.hasValue, isTrue, reason: 'previous value phải còn');
      expect(profileGateOf(refreshing), ProfileGate.loading);
    });
    test('error kèm previous value -> error (không dùng identity cũ)', () async {
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
      expect(profileGateOf(errored), ProfileGate.error);
    });
    test('error không previous -> error', () {
      expect(
        profileGateOf(AsyncError<Profile?>(StateError('x'), StackTrace.empty)),
        ProfileGate.error,
      );
    });
    test('data(null) -> missing (chưa có hồ sơ)', () {
      expect(
        profileGateOf(const AsyncData<Profile?>(null)),
        ProfileGate.missing,
      );
    });
    test('data(profile) -> present', () {
      expect(
        profileGateOf(const AsyncData<Profile?>(oldUser)),
        ProfileGate.present,
      );
    });
  });
}
