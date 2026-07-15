import '../../../l10n/app_localizations.dart';

/// Phân loại lỗi các RPC swipe từ server — hiện là record_swipe, thêm
/// undo_last_swipe khi tính năng rewind lên (message chứa mã lỗi do plpgsql
/// raise — cùng pattern keo_errors.dart).
/// [L10N] message giữ VI làm fallback; UI truyền l10n qua [localizedMessage].
enum DiscoverySwipeError {
  likeLimit('Bạn đã hết lượt thích hôm nay. Nâng cấp Pro để thích không giới hạn.'),
  superLimit('Bạn đã hết lượt Siêu thích hôm nay.'),
  proRequired('Tính năng này dành cho thành viên Pro.'),
  boostActive('Bạn đang trong một lượt boost.'),
  boostLimit('Bạn đã dùng hết lượt boost hôm nay. Thử lại vào ngày mai.'),
  unknown('Không lưu được lượt vuốt. Thử lại sau.');

  const DiscoverySwipeError(this.message);
  final String message;

  String localizedMessage(AppLocalizations? l10n) => switch (this) {
        likeLimit => l10n?.deckErrorLikeLimit ?? message,
        superLimit => l10n?.deckErrorSuperLimit ?? message,
        proRequired => l10n?.deckErrorProRequired ?? message,
        boostActive => l10n?.deckErrorBoostActive ?? message,
        boostLimit => l10n?.deckErrorBoostLimit ?? message,
        unknown => l10n?.deckErrorUnknown ?? message,
      };
}

DiscoverySwipeError discoverySwipeError(Object e) {
  final s = e.toString();
  if (s.contains('like_limit')) return DiscoverySwipeError.likeLimit;
  if (s.contains('super_limit')) return DiscoverySwipeError.superLimit;
  if (s.contains('pro_required')) return DiscoverySwipeError.proRequired;
  if (s.contains('boost_active')) return DiscoverySwipeError.boostActive;
  if (s.contains('boost_limit')) return DiscoverySwipeError.boostLimit;
  return DiscoverySwipeError.unknown;
}
