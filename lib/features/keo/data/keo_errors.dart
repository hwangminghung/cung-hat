/// Maps raw Supabase error text to a stable code / Vietnamese message.
/// The server raises bare codes like 'pro_required' as the exception message.
const _messages = <String, String>{
  'pro_required': 'Cần gói Pro để tạo kèo.',
  'free_join_limit':
      'Bạn đang tham gia 1 kèo. Rời kèo cũ hoặc nâng cấp Pro để tham gia thêm.',
  'keo_full': 'Kèo đã đầy.',
  'already_declined': 'Bạn đã bị từ chối ở kèo này.',
  'keo_not_open': 'Kèo không còn mở.',
  'blocked': 'Khong the vao keo nay vi cai dat an toan.',
  'location_required':
      'Can bat vi tri de ghep keo. Hay bat Location roi thu lai.',
  'age_not_verified': 'Can xac minh tuoi truoc khi ghep keo.',
  'no_matchable_keo': 'Chua tim duoc keo phu hop, thu lai sau.',
  'invalid_time_window': 'Gio hen khong hop le. Hay chon khung gio khac.',
  'invalid_group_size': 'So nguoi trong keo khong hop le.',
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
