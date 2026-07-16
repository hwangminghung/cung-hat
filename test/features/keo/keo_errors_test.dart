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

  test('free_host_limit (P1-5 đảo gate) map đúng code + message', () {
    expect(
      keoErrorCode('PostgrestException(message: free_host_limit, code: 23514)'),
      'free_host_limit',
    );
    expect(
      keoErrorMessage('... free_host_limit ...'),
      'Gói Free giữ 1 kèo đang mở. Huỷ kèo cũ hoặc nâng cấp Pro để tạo thêm.',
    );
  });
}
