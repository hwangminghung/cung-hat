import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/data/discovery_errors.dart';

void main() {
  test('map các mã lỗi swipe sang copy VI', () {
    expect(
      discoverySwipeError(Exception('like_limit x')),
      DiscoverySwipeError.likeLimit,
    );
    expect(
      discoverySwipeError(Exception('super_limit')),
      DiscoverySwipeError.superLimit,
    );
    expect(
      discoverySwipeError(Exception('pro_required')),
      DiscoverySwipeError.proRequired,
    );
    // [MATCH-AUDIT #1a] activate_boost nay raise boost_required cho người
    // chưa mua — không được rơi vào unknown, càng không được nói "cần Pro"
    // với người đã trả 49k mà boost hết hạn.
    expect(
      discoverySwipeError(Exception('boost_required')),
      DiscoverySwipeError.boostRequired,
    );
    expect(discoverySwipeError(Exception('boom')), DiscoverySwipeError.unknown);
    expect(DiscoverySwipeError.likeLimit.message, contains('lượt thích'));
  });
}
