import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/onboarding/presentation/dob_step.dart';

void main() {
  test('isAdult true for >=18', () {
    expect(isAdult(DateTime(2000, 1, 1), now: DateTime(2026, 6, 20)), isTrue);
  });
  test('isAdult false for <18', () {
    expect(isAdult(DateTime(2010, 1, 1), now: DateTime(2026, 6, 20)), isFalse);
  });
  test('isAdult false exactly one day before 18th birthday', () {
    expect(isAdult(DateTime(2008, 6, 21), now: DateTime(2026, 6, 20)), isFalse);
  });
}
