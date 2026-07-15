// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Cùng Hát';

  @override
  String get tabDoi => 'Đôi';

  @override
  String get tabKeo => 'Kèo';

  @override
  String get comingSoon => 'Sắp có';

  @override
  String get authTitle => 'Đăng nhập';

  @override
  String get phoneLabel => 'Số điện thoại';

  @override
  String get sendOtp => 'Gửi mã OTP';

  @override
  String get otpTitle => 'Nhập mã OTP';

  @override
  String get otpLabel => 'Mã 6 số';

  @override
  String get verify => 'Xác nhận';

  @override
  String get onbDobTitle => 'Bạn sinh ngày nào?';

  @override
  String get onbUnder18 => 'Bạn phải đủ 18 tuổi để dùng ứng dụng.';

  @override
  String get onbConsentTitle => 'Quyền riêng tư';

  @override
  String get onbConsentSubtitle => 'Bạn chọn cách Cùng Hát dùng dữ liệu';

  @override
  String get onbRequired => 'Bắt buộc';

  @override
  String get onbConsentContinue => 'Đồng ý & tiếp tục';

  @override
  String get onbNameLabel => 'Tên hiển thị';

  @override
  String get onbBioLabel => 'Giới thiệu';

  @override
  String get onbTasteGenres => 'Thể loại';

  @override
  String get onbTasteArtists => 'Nghệ sĩ';

  @override
  String get onbBaitu => 'Bài tủ';

  @override
  String get onbFinish => 'Hoàn tất';

  @override
  String get onbConsentRequired =>
      'Vui lòng đồng ý các quyền bắt buộc để tiếp tục.';

  @override
  String get onbSetupTitle => 'Thiết lập hồ sơ';

  @override
  String get onbStepDob => 'Ngày sinh';

  @override
  String get onbStepProfile => 'Thiết lập hồ sơ';

  @override
  String get onbProfileQuestion => 'Bạn muốn mọi người gọi mình là gì?';

  @override
  String get onbStepTaste => 'Gu nhạc';

  @override
  String get onbTasteSubtitle => 'Chọn vài thứ bạn hay nghe';

  @override
  String onbProgress(int step) {
    return 'Bước $step/4';
  }

  @override
  String get onbDobDay => 'Ngày';

  @override
  String get onbDobMonth => 'Tháng';

  @override
  String get onbDobYear => 'Năm';

  @override
  String get onbContinue => 'Tiếp tục';

  @override
  String get onbBack => 'Quay lại';

  @override
  String get onbLoadError => 'Không tải được dữ liệu.';

  @override
  String get onbSubmitError => 'Có lỗi xảy ra, vui lòng thử lại.';

  @override
  String get consentLocation => 'Dùng vị trí để gợi ý người/kèo gần bạn';

  @override
  String get consentPhotos => 'Lưu và hiển thị ảnh hồ sơ';

  @override
  String get consentMatching => 'Dùng gu nhạc để ghép người';

  @override
  String get consentMarketing => 'Nhận thông báo khuyến mãi';

  @override
  String get consentCrossBorder =>
      'Tôi đồng ý Chính sách bảo mật, Điều khoản và việc lưu dữ liệu tại Singapore';

  @override
  String get chatPromoteKeo => 'Lập kèo';

  @override
  String get sendThisTitle => 'Gửi tin này?';

  @override
  String get sendThisBody =>
      'Tin này có thể chứa thông tin tài chính/liên hệ. Vẫn gửi?';

  @override
  String get cancel => 'Hủy';

  @override
  String get send => 'Gửi';

  @override
  String get privacyTitle => 'Chính sách bảo mật';

  @override
  String get tosTitle => 'Điều khoản sử dụng';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get exportData => 'Tải dữ liệu của tôi';

  @override
  String get deleteAccount => 'Xoá tài khoản';

  @override
  String get deleteConfirm =>
      'Hành động này không thể hoàn tác. Tài khoản và dữ liệu của bạn sẽ bị xoá.';

  @override
  String get storeTitle => 'Nâng cấp';

  @override
  String get boostTitle => 'Đẩy kèo lên top';

  @override
  String get seeLikesTitle => 'Xem ai đã thích bạn';

  @override
  String get filtersTitle => 'Bộ lọc nâng cao';

  @override
  String get buy => 'Mua';

  @override
  String get bookVenue => 'Đặt phòng & giữ chỗ';

  @override
  String get entitlementNeeded => 'Cần nâng cấp để dùng tính năng này';

  @override
  String get authTagline => 'Kết bạn qua những bài hát';

  @override
  String get authPhoneTitle => 'Đăng nhập bằng số điện thoại';

  @override
  String get authPhoneBody =>
      'Nhập số của bạn để nhận mã OTP. Tụi mình chỉ dùng để giữ tài khoản an toàn.';

  @override
  String get authPhoneHint => '901 234 567';

  @override
  String get authResponsibility =>
      'Bằng việc tiếp tục, bạn đồng ý dùng Cùng Hát có trách nhiệm và tôn trọng người khác.';

  @override
  String get authSendOtpError => 'Không gửi được mã';

  @override
  String authResendCountdown(int seconds) {
    return 'Gửi lại mã sau ${seconds}s';
  }

  @override
  String get authResend => 'Gửi lại mã';

  @override
  String get authCheckMessages => 'Kiểm tra tin nhắn';

  @override
  String get authOtpSentPrefix => 'Mã đã gửi tới ';

  @override
  String authOtpSentTo(String phone) {
    return 'Mã đã gửi tới $phone';
  }

  @override
  String get authPhoneFallback => 'số điện thoại của bạn';

  @override
  String get authOtpHelp =>
      'Không nhận được mã? Quay lại để kiểm tra số điện thoại.';

  @override
  String get authOtpError => 'Mã OTP chưa đúng';

  @override
  String get discoveryDeckTitle => 'Đôi hát';

  @override
  String get discoveryDeckSubtitle =>
      'Gợi ý hợp gu nhạc và khoảng cách an toàn.';

  @override
  String get discoveryRewind => 'Quay lại';

  @override
  String get discoveryPass => 'Bỏ qua';

  @override
  String get discoverySuperLike => 'Siêu thích';

  @override
  String get discoveryLike => 'Thích';

  @override
  String get discoveryExploreTitle => 'Khám phá theo gu nhạc';

  @override
  String get discoveryExploreSubtitle =>
      'Chọn một mood, gặp người cùng tần số.';

  @override
  String get discoveryExploreOpen => 'Đang mở';

  @override
  String discoveryExploreLiveCount(int count) {
    return '$count người đang hát';
  }

  @override
  String get discoveryExploreBrand => 'CÙNG HÁT';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabProfile => 'Hồ sơ';

  @override
  String get shellTileLikes => 'Ai đã thích bạn';

  @override
  String get shellTileLikesSub => 'Mở danh sách người đã thả tim';

  @override
  String get shellTileUpgradeSub => 'Pro, boost kèo và bộ lọc nâng cao';

  @override
  String get shellTilePhotos => 'Ảnh hồ sơ';

  @override
  String get shellTilePhotosSub => 'Thêm tối đa 6 ảnh vào hồ sơ';

  @override
  String get shellTilePrompts => 'Thẻ hỏi-đáp';

  @override
  String get shellTilePromptsSub =>
      'Chọn tối đa 3 câu để hồ sơ có chuyện mà bắt';

  @override
  String get shellTileSettingsSub => 'Quyền riêng tư, dữ liệu và pháp lý';

  @override
  String get shellProfileSub => 'Quản lý lượt thích, gói nâng cấp và cài đặt.';

  @override
  String completionPercent(int percent) {
    return 'Hồ sơ hoàn thiện $percent%';
  }

  @override
  String get completionAddPhoto =>
      'Thêm ảnh đầu tiên → được thấy nhiều hơn hẳn';

  @override
  String get completionThreePhotos => 'Đủ 3 ảnh → x2 lượt được thấy';

  @override
  String get completionWriteBio => 'Viết bio → +25% match';

  @override
  String get completionPickGenres => 'Chọn đủ 3 thể loại → gợi ý chuẩn gu hơn';

  @override
  String get completionAddArtist => 'Thêm nghệ sĩ yêu thích';

  @override
  String get completionAddBaitu => 'Thêm 3 bài tủ → dễ vào kèo hơn';

  @override
  String get completionAnswerPrompts =>
      'Trả lời 2 thẻ hỏi-đáp → có chuyện mà bắt';

  @override
  String get upsellCta => 'Nâng cấp Pro';

  @override
  String get upsellLater => 'Để sau';

  @override
  String get upsellAllProPerks => 'Kèm mọi quyền lợi Pro khác';

  @override
  String get upsellBoostTitle => 'Boost hồ sơ của bạn';

  @override
  String get upsellBoostB1 => '1 lần Boost 30 phút mỗi ngày';

  @override
  String get upsellBoostB2 => 'Lên đầu deck của mọi người quanh đây';

  @override
  String get upsellRewindTitle => 'Rút lại lượt vuốt';

  @override
  String get upsellRewindB1 => 'Lỡ tay bỏ qua? Rút lại ngay lượt gần nhất';

  @override
  String get upsellRewindB2 => 'Không giới hạn số lần rút lại';

  @override
  String get upsellSeeLikesTitle => 'Xem ai đã thích bạn';

  @override
  String get upsellSeeLikesB1 => 'Mở danh sách người đã thả tim bạn';

  @override
  String get upsellSeeLikesB2 => 'Match ngay không cần vuốt trúng';

  @override
  String get upsellKeoCreateTitle => 'Tự tạo kèo của riêng bạn';

  @override
  String get upsellKeoCreateB1 => 'Làm chủ kèo: chọn quán, giờ, thành viên';

  @override
  String get upsellKeoCreateB2 => 'Kèo mở hoặc cần duyệt — bạn quyết';

  @override
  String get upsellKeoJoinTitle => 'Tham gia nhiều kèo cùng lúc';

  @override
  String get upsellKeoJoinB1 => 'Miễn phí chỉ được 1 kèo đang hoạt động';

  @override
  String get upsellKeoJoinB2 => 'Pro tham gia không giới hạn kèo';

  @override
  String get upsellLikeQuotaTitle => 'Hết lượt thích hôm nay';

  @override
  String get upsellLikeQuotaB1 => 'Pro thích không giới hạn mỗi ngày';

  @override
  String get upsellLikeQuotaB2 => '5 Siêu thích mỗi ngày';

  @override
  String get upsellSuperQuotaTitle => 'Hết lượt Siêu thích hôm nay';

  @override
  String get upsellSuperQuotaB1 => 'Pro có 5 Siêu thích mỗi ngày';

  @override
  String get upsellSuperQuotaB2 => 'Siêu thích giúp bạn nổi bật gấp 3 lần';

  @override
  String get onbLoadRetrySub => 'Thử lại sau ít phút.';

  @override
  String get onbTasteEmptyTitle => 'Chưa có dữ liệu gu nhạc';

  @override
  String get onbTasteEmptySub =>
      'Kiểm tra dữ liệu mẫu hoặc thử tải lại sau ít phút.';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonCheckConnection => 'Kiểm tra kết nối rồi thử lại.';

  @override
  String get commonSaveError => 'Không lưu được cài đặt, thử lại.';

  @override
  String get deckErrorLikeLimit =>
      'Bạn đã hết lượt thích hôm nay. Nâng cấp Pro để thích không giới hạn.';

  @override
  String get deckErrorSuperLimit => 'Bạn đã hết lượt Siêu thích hôm nay.';

  @override
  String get deckErrorProRequired => 'Tính năng này dành cho thành viên Pro.';

  @override
  String get deckErrorBoostActive => 'Bạn đang trong một lượt boost.';

  @override
  String get deckErrorBoostLimit =>
      'Bạn đã dùng hết lượt boost hôm nay. Thử lại vào ngày mai.';

  @override
  String get deckErrorUnknown => 'Không lưu được lượt vuốt. Thử lại sau.';

  @override
  String get candidateFallbackName => 'Bạn hát mới';

  @override
  String get commonReport => 'Báo cáo';

  @override
  String get candidateViewProfile => 'Xem hồ sơ';

  @override
  String get candidateOnlineToday => 'Online hôm nay';

  @override
  String candidateDistanceKm(String band) {
    return 'Cách $band km';
  }

  @override
  String candidateSharedBaitu(int count) {
    return 'cùng $count bài tủ';
  }

  @override
  String get candidateNoSharedGenres => 'Chưa chung thể loại nào';

  @override
  String get candidateNoBio => 'Chưa có giới thiệu — hỏi thử khi match nhé!';

  @override
  String get candidatePhotoQuote => 'Ảnh này xịn quá! ';

  @override
  String get candidateReplyPhoto => 'Trả lời ảnh này';

  @override
  String get candidateSharedGenresTitle => 'Gu nhạc chung';

  @override
  String get candidateNoSharedGenresDot => 'Chưa trùng thể loại nào.';

  @override
  String get candidateSharedBaituTitle => 'Bài tủ chung';

  @override
  String get candidateNoSharedBaitu =>
      'Chưa có bài tủ chung — cơ hội khám phá!';

  @override
  String candidateSongQuote(String title) {
    return 'Về bài \"$title\" của bạn: ';
  }

  @override
  String get candidateReply => 'Trả lời';

  @override
  String candidatePromptQuote(String answer) {
    return 'Bạn nói \"$answer\" — kể thêm đi: ';
  }

  @override
  String get candidateReportBlock => 'Báo cáo / Chặn';

  @override
  String get exploreFallbackTitle => 'Khám Phá';

  @override
  String get deckLoadErrorTitle => 'Không tải được gợi ý';

  @override
  String get deckPromoSeeKeo => 'XEM KÈO';

  @override
  String get deckExploreTooltip => 'Khám Phá theo gu nhạc';

  @override
  String get deckRefreshTooltip => 'Làm mới';

  @override
  String get deckSearching100 => 'Đang tìm trong 100 km';

  @override
  String deckBoostingUntil(String time) {
    return 'Đang boost đến $time';
  }

  @override
  String get deckBoostTooltip => 'Boost hồ sơ';

  @override
  String get deckBoostStarted =>
      'Đang boost 30 phút — hồ sơ của bạn được ưu tiên quanh đây.';

  @override
  String get celebrateYouFallback => 'Bạn';

  @override
  String get deckExhausted100 => 'Đã tìm hết trong 100 km';

  @override
  String get deckEmptyNearby => 'Chưa có bạn hát quanh đây';

  @override
  String get deckExpand100 => 'Mở rộng tìm quanh 100 km';

  @override
  String get deckRefreshSuggestions => 'Làm mới gợi ý';

  @override
  String get deckAutoExpandTitle => 'Tự mở rộng khi hết người';

  @override
  String get deckAutoExpandSub => 'Tự động tìm quanh 100 km khi 50 km đã hết';

  @override
  String get filterApplied => 'Đã áp dụng bộ lọc.';

  @override
  String get filterSaveError => 'Không lưu được, thử lại.';

  @override
  String get filterTitle => 'Bộ lọc';

  @override
  String get filterRadius => 'Bán kính tìm quanh';

  @override
  String get filterAutoExpandSub => 'Tự tìm quanh 100 km khi hết gợi ý';

  @override
  String get filterApply => 'Áp dụng';

  @override
  String get promoKeoNearby => '🎤 Kèo gần bạn';

  @override
  String promoSeats(int filled, int target) {
    return '$filled/$target chỗ';
  }

  @override
  String promoDistanceKm(String band) {
    return 'cách $band km';
  }

  @override
  String get promoSwipeRight => 'Vuốt phải để xem kèo →';

  @override
  String get likesEmptyTitle => 'Chưa có ai thích bạn';

  @override
  String get likesEmptySub => 'Cứ hát hết mình, người hợp gu sẽ tới.';

  @override
  String get likesAnonymous => 'Ẩn danh';

  @override
  String get likesLockedTitle => 'Mở khóa để xem ai đã thích bạn';

  @override
  String get teaserLoadError => 'Không tải được danh sách';

  @override
  String get teaserEmptySub => 'Hoàn thiện hồ sơ để được thấy nhiều hơn nhé.';

  @override
  String teaserCount(int count) {
    return '$count người đã thích bạn';
  }

  @override
  String get teaserUnlockCta => 'Mở khoá với Pro — xem ai thích bạn';

  @override
  String get celebrateTitle => 'Hợp cạ rồi!';

  @override
  String celebrateBody(String name) {
    return 'Bạn và $name đã thích nhau';
  }

  @override
  String celebrateSharedBaitu(String songs) {
    return 'Cùng tủ: $songs';
  }

  @override
  String get celebrateChatNow => 'Nhắn tin ngay';

  @override
  String get celebrateContinue => 'Tiếp tục khám phá';

  @override
  String reportTitle(String reason) {
    return 'Báo cáo: $reason';
  }

  @override
  String get reportBlockUser => 'Chặn người này';

  @override
  String get reportSent => 'Đã gửi báo cáo.';

  @override
  String get reportSendError => 'Không gửi được báo cáo.';

  @override
  String get reportBlocked => 'Đã chặn.';

  @override
  String get reportBlockError => 'Không chặn được.';

  @override
  String exploreOpenSemantics(String title) {
    return 'Mở $title';
  }
}
