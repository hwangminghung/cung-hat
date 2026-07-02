import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/router.dart';

void main() {
  test('unauthenticated is sent to /auth', () {
    expect(authRedirect(signedIn: false, hasProfile: false, location: '/'), '/auth');
  });
  test('signed-in without profile goes to /onboarding', () {
    expect(authRedirect(signedIn: true, hasProfile: false, location: '/'), '/onboarding');
  });
  test('signed-in with profile on /auth goes home', () {
    expect(authRedirect(signedIn: true, hasProfile: true, location: '/auth'), '/');
  });
  test('signed-in with profile on /otp goes home', () {
    expect(authRedirect(signedIn: true, hasProfile: true, location: '/otp'), '/');
  });
  test('signed-in with profile leaves /onboarding for home', () {
    expect(authRedirect(signedIn: true, hasProfile: true, location: '/onboarding'), '/');
  });
  test('signed-in with profile elsewhere is not redirected', () {
    expect(authRedirect(signedIn: true, hasProfile: true, location: '/'), isNull);
  });
  test('unauthenticated can view a shared plan', () {
    expect(authRedirect(signedIn: false, hasProfile: false, location: '/plan/shared/tok'), isNull);
  });

  // Profile chưa load xong (null = unknown): đứng yên chờ, KHÔNG được đoán
  // /onboarding — tránh flash màn onboarding cho user đã có hồ sơ (bug OTP kẹt).
  test('signed-in with profile still loading holds position on /otp', () {
    expect(authRedirect(signedIn: true, hasProfile: null, location: '/otp'), isNull);
  });
  test('signed-in with profile still loading holds position on /', () {
    expect(authRedirect(signedIn: true, hasProfile: null, location: '/'), isNull);
  });
  test('signed-in with profile still loading holds position on /onboarding', () {
    expect(authRedirect(signedIn: true, hasProfile: null, location: '/onboarding'), isNull);
  });
}
