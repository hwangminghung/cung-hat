/// Maps raw Supabase error text to a stable code / Vietnamese message.
/// The server raises bare codes like 'pro_required' as the exception message.
const _messages = <String, String>{
  'pro_required': 'Cần gói Pro để tạo kèo.',
  'free_join_limit':
      'Bạn đang tham gia 1 kèo. Rời kèo cũ hoặc nâng cấp Pro để tham gia thêm.',
  'keo_full': 'Kèo đã đầy.',
  'already_declined': 'Bạn đã bị từ chối ở kèo này.',
  'keo_not_open': 'Kèo không còn mở.',
  'blocked': 'Không thể vào kèo này vì cài đặt an toàn.',
  'location_required':
      'Cần bật vị trí để ghép kèo. Hãy bật Location rồi thử lại.',
  'age_not_verified': 'Cần xác minh tuổi trước khi ghép kèo.',
  'no_matchable_keo': 'Chưa tìm được kèo phù hợp, thử lại sau.',
  'invalid_time_window': 'Giờ hẹn không hợp lệ. Hãy chọn khung giờ khác.',
  'invalid_group_size': 'Số người trong kèo không hợp lệ.',
};

String? keoErrorCode(Object error) {
  final text = error.toString();
  for (final code in _messages.keys) {
    if (text.contains(code)) return code;
  }
  return null;
}

String keoErrorMessage(Object error) {
  final code = keoErrorCode(error);
  return _messages[code] ?? 'Có lỗi xảy ra, thử lại.';
}
