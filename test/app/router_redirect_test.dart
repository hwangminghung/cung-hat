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
  test('signed-in with profile elsewhere is not redirected', () {
    expect(authRedirect(signedIn: true, hasProfile: true, location: '/'), isNull);
  });
}
