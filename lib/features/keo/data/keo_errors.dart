/// Maps raw Supabase error text to a stable code / Vietnamese message.
/// The server raises bare codes like 'pro_required' as the exception message.
const _messages = <String, String>{
  'pro_required': 'Cần gói Pro để tạo kèo.',
  'free_join_limit':
      'Bạn đang tham gia 1 kèo. Rời kèo cũ hoặc nâng cấp Pro để tham gia thêm.',
  'keo_full': 'Kèo đã đầy.',
  'already_declined': 'Bạn đã bị từ chối ở kèo này.',
  'keo_not_open': 'Kèo không còn mở.',
};

String? keoErrorCode(Object error) {
  final s = error.toString();
  for (final code in _messages.keys) {
    if (s.contains(code)) return code;
  }
  return null;
}

String keoErrorMessage(Object error) {
  final code = keoErrorCode(error);
  return _messages[code] ?? 'Có lỗi xảy ra, thử lại.';
}
