import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/onboarding/presentation/consent_step.dart';

void main() {
  test('requiredConsents is the exact four-purpose mandatory set', () {
    expect(
      requiredConsents,
      unorderedEquals(<String>{
        'location',
        'photos',
        'matching',
        'cross_border',
      }),
    );
  });

  test('missingRequiredConsents returns ungranted required purposes', () {
    expect(
      missingRequiredConsents(const {
        'location': false,
        'photos': false,
        'matching': false,
        'cross_border': false,
      }),
      unorderedEquals(<String>{
        'location',
        'photos',
        'matching',
        'cross_border',
      }),
    );
  });

  test('missingRequiredConsents empty when all required granted', () {
    expect(
      missingRequiredConsents(const {
        'location': true,
        'photos': true,
        'matching': true,
        'marketing': false,
        'cross_border': true,
      }),
      isEmpty,
    );
  });

  test('optional consents do not count as missing', () {
    expect(
      missingRequiredConsents(const {
        'location': true,
        'photos': true,
        'matching': true,
        'marketing': false,
        'cross_border': true,
      }),
      isEmpty,
    );
  });

  test(
    'grantRequiredConsents grants four required and keeps marketing off',
    () {
      final values = {for (final purpose in consentPurposes) purpose: false};

      grantRequiredConsents(values);

      expect(
        {for (final purpose in requiredConsents) purpose: values[purpose]},
        {for (final purpose in requiredConsents) purpose: true},
      );
      expect(values['marketing'], isFalse);
    },
  );

  test('grantRequiredConsents preserves an enabled marketing choice', () {
    final values = {
      for (final purpose in consentPurposes) purpose: purpose == 'marketing',
    };

    grantRequiredConsents(values);

    expect(values['marketing'], isTrue);
    expect(missingRequiredConsents(values), isEmpty);
  });
}
