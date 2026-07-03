/// Phân loại lỗi các RPC swipe từ server — hiện là record_swipe, thêm
/// undo_last_swipe khi tính năng rewind lên (message chứa mã lỗi do plpgsql
/// raise — cùng pattern keo_errors.dart).
enum DiscoverySwipeError {
  likeLimit('Bạn đã hết lượt thích hôm nay. Nâng cấp Pro để thích không giới hạn.'),
  superLimit('Bạn đã hết lượt Siêu thích hôm nay.'),
  proRequired('Tính năng này dành cho thành viên Pro.'),
  unknown('Không lưu được lượt vuốt. Thử lại sau.');

  const DiscoverySwipeError(this.message);
  final String message;
}

DiscoverySwipeError discoverySwipeError(Object e) {
  final s = e.toString();
  if (s.contains('like_limit')) return DiscoverySwipeError.likeLimit;
  if (s.contains('super_limit')) return DiscoverySwipeError.superLimit;
  if (s.contains('pro_required')) return DiscoverySwipeError.proRequired;
  return DiscoverySwipeError.unknown;
}
