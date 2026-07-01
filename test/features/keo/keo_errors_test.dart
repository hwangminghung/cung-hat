import 'package:cung_hat/features/keo/data/keo_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps known keo error codes', () {
    expect(
      keoErrorCode('PostgrestException(message: pro_required, code: 23514)'),
      'pro_required',
    );
    expect(keoErrorCode('... free_join_limit ...'), 'free_join_limit');
    expect(keoErrorMessage('something else'), isNotEmpty);
  });

  test('maps boost errors', () {
    expect(
      keoErrorCode('PostgrestException(message: no_boost_credit)'),
      'no_boost_credit',
    );
    expect(
      keoErrorMessage('PostgrestException(message: boost_already_active)'),
      'Keo nay dang duoc day.',
    );
  });
}
