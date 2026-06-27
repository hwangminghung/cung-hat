import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/keo/data/keo_errors.dart';

void main() {
  test('maps known keo error codes to Vietnamese', () {
    expect(keoErrorCode('PostgrestException(message: pro_required, code: 23514)'),
        'pro_required');
    expect(keoErrorMessage('... free_join_limit ...'),
        'Bạn đang tham gia 1 kèo. Rời kèo cũ hoặc nâng cấp Pro để tham gia thêm.');
    expect(keoErrorMessage('something else'), 'Có lỗi xảy ra, thử lại.');
  });
}
