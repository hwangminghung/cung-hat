import '../../../l10n/app_localizations.dart';

/// Maps raw Supabase error text to a stable code / Vietnamese message.
/// The server raises bare codes like 'pro_required' as the exception message.
/// [L10N] Map VI giữ làm fallback; UI truyền l10n vào [keoErrorMessage].
const _messages = <String, String>{
  'pro_required': 'Cần gói Pro để tạo kèo.',
  'free_host_limit':
      'Gói miễn phí chỉ giữ 1 kèo đang mở. Huỷ kèo cũ hoặc nâng cấp Pro để tạo thêm.',
  'free_join_limit':
      'Bạn đang tham gia 1 kèo. Rời kèo cũ hoặc nâng cấp Pro để tham gia thêm.',
  'keo_full': 'Kèo đã đầy.',
  'already_declined': 'Bạn đã bị từ chối ở kèo này.',
  'keo_not_open': 'Kèo không còn mở.',
  'blocked': 'Không thể vào kèo này vì cài đặt an toàn.',
  'location_required':
      'Cần bật vị trí để ghép kèo. Hãy bật vị trí rồi thử lại.',
  'age_not_verified': 'Cần xác minh tuổi trước khi ghép kèo.',
  'no_matchable_keo': 'Chưa tìm được kèo phù hợp, thử lại sau.',
  'invalid_time_window': 'Giờ hẹn không hợp lệ. Hãy chọn khung giờ khác.',
  'invalid_group_size': 'Số người trong kèo không hợp lệ.',
};

String? _localized(String? code, AppLocalizations? l10n) => switch (code) {
  'pro_required' => l10n?.keoErrorProRequired,
  'free_host_limit' => l10n?.keoErrorFreeHostLimit,
  'free_join_limit' => l10n?.keoErrorFreeJoinLimit,
  'keo_full' => l10n?.keoErrorFull,
  'already_declined' => l10n?.keoErrorAlreadyDeclined,
  'keo_not_open' => l10n?.keoErrorNotOpen,
  'blocked' => l10n?.keoErrorBlocked,
  'location_required' => l10n?.keoErrorNoLocation,
  'age_not_verified' => l10n?.keoErrorAgeNotVerified,
  'no_matchable_keo' => l10n?.keoErrorNoMatchableKeo,
  'invalid_time_window' => l10n?.keoErrorInvalidTimeWindow,
  'invalid_group_size' => l10n?.keoErrorInvalidGroupSize,
  _ => null,
};

String? keoErrorCode(Object error) {
  final text = error.toString();
  for (final code in _messages.keys) {
    if (text.contains(code)) return code;
  }
  return null;
}

String keoErrorMessage(Object error, [AppLocalizations? l10n]) {
  final code = keoErrorCode(error);
  return _localized(code, l10n) ??
      _messages[code] ??
      (l10n?.keoErrorGeneric ?? 'Có lỗi xảy ra, thử lại.');
}
