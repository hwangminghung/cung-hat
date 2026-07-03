import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/data/discovery_errors.dart';

void main() {
  test('map các mã lỗi swipe sang copy VI', () {
    expect(discoverySwipeError(Exception('like_limit x')),
        DiscoverySwipeError.likeLimit);
    expect(discoverySwipeError(Exception('super_limit')),
        DiscoverySwipeError.superLimit);
    expect(discoverySwipeError(Exception('pro_required')),
        DiscoverySwipeError.proRequired);
    expect(discoverySwipeError(Exception('boom')),
        DiscoverySwipeError.unknown);
    expect(DiscoverySwipeError.likeLimit.message, contains('lượt thích'));
  });
}
