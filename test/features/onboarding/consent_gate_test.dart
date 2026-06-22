import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/onboarding/presentation/consent_step.dart';

void main() {
  test('missingRequiredConsents returns ungranted required purposes', () {
    expect(missingRequiredConsents(const {'matching': false, 'cross_border': false}),
        containsAll(<String>['matching', 'cross_border']));
  });
  test('missingRequiredConsents empty when all required granted', () {
    expect(missingRequiredConsents(const {'matching': true, 'cross_border': true, 'marketing': false}),
        isEmpty);
  });
  test('optional consents do not count as missing', () {
    expect(missingRequiredConsents(const {'matching': true, 'cross_border': true, 'location': false}),
        isEmpty);
  });
}
