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
      'Tin nhắn có vẻ liên quan tới tiền bạc hoặc thông tin nhạy cảm. Hãy kiểm tra kỹ trước khi gửi.';

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

  @override
  String get keoErrorProRequired => 'Cần gói Pro để tạo kèo.';

  @override
  String get keoErrorFreeJoinLimit =>
      'Bạn đang tham gia 1 kèo. Rời kèo cũ hoặc nâng cấp Pro để tham gia thêm.';

  @override
  String get keoErrorFull => 'Kèo đã đầy.';

  @override
  String get keoErrorAlreadyDeclined => 'Bạn đã bị từ chối ở kèo này.';

  @override
  String get keoErrorNotOpen => 'Kèo không còn mở.';

  @override
  String get keoErrorBlocked => 'Không thể vào kèo này vì cài đặt an toàn.';

  @override
  String get keoErrorNoLocation =>
      'Cần bật vị trí để ghép kèo. Hãy bật Location rồi thử lại.';

  @override
  String get keoErrorAgeNotVerified => 'Cần xác minh tuổi trước khi ghép kèo.';

  @override
  String get keoErrorNoMatchableKeo =>
      'Chưa tìm được kèo phù hợp, thử lại sau.';

  @override
  String get keoErrorInvalidTimeWindow =>
      'Giờ hẹn không hợp lệ. Hãy chọn khung giờ khác.';

  @override
  String get keoErrorInvalidGroupSize => 'Số người trong kèo không hợp lệ.';

  @override
  String get keoErrorGeneric => 'Có lỗi xảy ra, thử lại.';

  @override
  String get keoModeOpen => 'Mở · vào là tham gia';

  @override
  String get keoModeApproval => 'Cần duyệt';

  @override
  String keoCardDistance(String band) {
    return 'cách $band km';
  }

  @override
  String keoCardPeople(int filled, int target) {
    return '$filled/$target người';
  }

  @override
  String get keoBoardLoadError => 'Không tải được danh sách kèo';

  @override
  String get keoBoardEmptyTitle => 'Chưa có kèo quanh đây';

  @override
  String get keoBoardEmptySub =>
      'Bấm ghép nhóm để tìm kèo hợp gu hoặc tự tạo một kèo mới.';

  @override
  String get keoCreateCta => 'Tạo kèo';

  @override
  String get keoBoardTitle => 'Kèo quanh bạn';

  @override
  String get keoBoardStoreTooltip => 'Cửa hàng';

  @override
  String get keoBoardSubtitle =>
      'Tìm nhóm đi hát hợp gu, gần bạn và có lịch phù hợp.';

  @override
  String get keoBoardMatchMe => 'Ghép nhóm cho tôi';

  @override
  String get keoBoardMatchMeSub =>
      'Tự động gợi ý kèo hợp gu, gần bạn và đúng khung giờ.';

  @override
  String get keoSharedTitle => 'Kèo được chia sẻ';

  @override
  String get keoSharedLoadError => 'Không tải được kèo';

  @override
  String get keoSharedNotFound => 'Không tìm thấy kèo';

  @override
  String get keoSharedNotFoundSub => 'Link không đúng hoặc kèo đã bị xoá.';

  @override
  String get keoSharedExpired => 'Link đã hết hạn';

  @override
  String keoSharedSeats(int filled, int target) {
    return '$filled/$target chỗ';
  }

  @override
  String keoSharedHost(String name) {
    return 'Host: $name';
  }

  @override
  String get keoSharedAnonymous => 'Ẩn danh';

  @override
  String get keoSharedJoinCta => 'Xem kèo & xin vào';

  @override
  String get keoSharedLoginCta => 'Đăng nhập để xin vào';

  @override
  String get keoStatusConfirmedMember => 'Đã xác nhận';

  @override
  String get keoStatusApproved => 'Đã duyệt';

  @override
  String get keoStatusRequested => 'Chờ duyệt';

  @override
  String get keoStatusLeft => 'Đã rời';

  @override
  String get keoStatusDeclined => 'Bị từ chối';

  @override
  String get keoDetailTitle => 'Chi tiết kèo';

  @override
  String get keoDetailShareTooltip => 'Chia sẻ kèo';

  @override
  String keoDetailShareMessage(String title, String link) {
    return 'Kèo \"$title\" đang tuyển giọng ca — vào Cùng Hát xin một chỗ: $link';
  }

  @override
  String get keoDetailShareError => 'Không tạo được link, thử lại.';

  @override
  String get keoDetailMembers => 'Thành viên';

  @override
  String get keoDetailApproveError => 'Không duyệt được';

  @override
  String get keoDetailDeclineError => 'Không từ chối được';

  @override
  String get keoDetailConfirmError => 'Không xác nhận được';

  @override
  String get keoDetailLeaveError => 'Không rời kèo được';

  @override
  String keoDetailMemberCount(int count) {
    return '$count người trong kèo';
  }

  @override
  String get keoDetailHostChip => 'Chủ kèo';

  @override
  String get keoDetailApprove => 'Duyệt';

  @override
  String get keoDetailDecline => 'Từ chối';

  @override
  String get keoDetailRequestJoin => 'Xin vào kèo';

  @override
  String get keoDetailConfirmJoin => 'Đồng ý tham gia';

  @override
  String get keoDetailConfirmed => 'Đã xác nhận tham gia';

  @override
  String get keoDetailOpenChat => 'Mở chat nhóm';

  @override
  String get keoDetailPickVenue => 'Chốt quán';

  @override
  String get keoDetailViewPlan => 'Xem kế hoạch';

  @override
  String get keoDetailLeave => 'Rời kèo';

  @override
  String get keoCreatePick => 'Chọn';

  @override
  String get keoCreateNameMissing => 'Nhập tên kèo';

  @override
  String get keoCreateTimeMissing => 'Chọn giờ bắt đầu và kết thúc';

  @override
  String get keoCreateTimeOrder => 'Giờ kết thúc phải sau giờ bắt đầu';

  @override
  String get keoCreateNoLocation =>
      'Không lấy được vị trí. Bật Location trên emulator rồi thử lại.';

  @override
  String get keoCreateHeadline => 'Rủ một nhóm đi hát';

  @override
  String get keoCreateSubtitle =>
      'Chọn thời gian, gu nhạc và cách duyệt thành viên.';

  @override
  String get keoCreateNameLabel => 'Tên kèo';

  @override
  String get keoCreateNameHint => 'V-Pop tối nay';

  @override
  String get keoCreateAreaLabel => 'Khu vực';

  @override
  String get keoCreateAreaHint => 'Quận 1, Hồ Chí Minh';

  @override
  String get keoCreateVenueLater => 'Chọn quán sau khi tạo kèo';

  @override
  String get keoCreateVenueLaterSub => 'Chủ kèo sẽ chốt quán ở màn Kế hoạch.';

  @override
  String keoCreateStart(String time) {
    return 'Bắt đầu: $time';
  }

  @override
  String keoCreateEnd(String time) {
    return 'Kết thúc: $time';
  }

  @override
  String get keoCreateSize => 'Số người';

  @override
  String keoCreateSizeN(int n) {
    return '$n người';
  }

  @override
  String get keoCreateGenres => 'Thể loại';

  @override
  String get keoCreateGenresError => 'Không tải được thể loại';

  @override
  String get keoCreateJoinMode => 'Chế độ tham gia';

  @override
  String get keoCreateModeApproval => 'Cần duyệt';

  @override
  String get keoCreateModeOpen => 'Mở';

  @override
  String get keoMatchNoneFound => 'Chưa tìm được kèo phù hợp. Thử lại sau.';

  @override
  String get keoMatchExistingTitle => 'Kèo hợp với bạn';

  @override
  String get keoMatchNewTitle => 'Đã tìm thấy nhóm phù hợp';

  @override
  String get commonClose => 'Đóng';

  @override
  String get keoMatchReasonSharedGenres => 'Hợp gu nhạc';

  @override
  String get keoMatchReasonNearYou => 'Gần bạn';

  @override
  String get keoMatchReasonEveningSlot => 'Giờ đẹp';

  @override
  String get keoMatchReasonOpenJoin => 'Vào nhanh';

  @override
  String get keoMatchReasonAvailableSlots => 'Còn chỗ';

  @override
  String get keoMatchReasonActiveHost => 'Chủ kèo đang online';

  @override
  String get chatShareSongTooltip => 'Gửi bài tủ';

  @override
  String get chatComposerHint => 'Nhắn gì đó...';

  @override
  String get chatSendError => 'Không gửi được tin nhắn. Thử lại sau.';

  @override
  String get chatProfileError => 'Không mở được hồ sơ. Thử lại sau.';

  @override
  String get chatProfileGone => 'Hồ sơ không còn.';

  @override
  String get chatUnmatchTitle => 'Huỷ ghép?';

  @override
  String get chatUnmatchBody => 'Hai bạn sẽ không nhắn tin được với nhau nữa.';

  @override
  String get chatUnmatchCta => 'Huỷ ghép';

  @override
  String get chatUnmatchError => 'Không huỷ ghép được, thử lại sau';

  @override
  String get chatEmptyMatch => 'Chưa có tin nhắn. Rủ nhau bằng một bài tủ đi.';

  @override
  String get chatEmptyKeo =>
      'Chưa có tin nhắn. Mở lời bằng một bài tủ của bạn.';

  @override
  String get chatHistoryError => 'Không tải được tin nhắn';

  @override
  String get chatGroupTitle => 'Chat nhóm';

  @override
  String get chatGroupRules => 'Luật nhóm';

  @override
  String get chatGroupRulesBody =>
      'Không quay/chụp khi chưa đồng ý · Chia tiền rõ ràng · Tôn trọng riêng tư';

  @override
  String get chatKeoNotOpen =>
      'Chưa mở chat nhóm. Cần tất cả thành viên đồng ý tham gia.';

  @override
  String get chatToday => 'Hôm nay';

  @override
  String get songShareEmpty =>
      'Bạn chưa chọn bài tủ nào. Vào Hồ sơ để thêm nhé.';

  @override
  String get inboxTitle => 'Tin nhắn';

  @override
  String get inboxSubtitle => 'Nơi giữ các cuộc trò chuyện sau khi chung gu.';

  @override
  String get inboxSectionKeo => 'Kèo của bạn';

  @override
  String get inboxSectionMatches => 'Tin nhắn đôi';

  @override
  String get inboxTurnFirst => 'Nhắn trước đi';

  @override
  String get inboxTurnYours => 'Đến lượt bạn';

  @override
  String get inboxReady => 'Sẵn sàng rủ đi hát';

  @override
  String get inboxEmptyTitle => 'Chưa có cuộc trò chuyện nào';

  @override
  String get inboxEmptySub =>
      'Tìm kèo ngay để bắt đầu trò chuyện với những người bạn mới!';

  @override
  String get inboxFindKeo => 'Tìm kèo ngay';

  @override
  String get inboxLoadError => 'Không tải được cuộc trò chuyện';

  @override
  String get keoStateOpen => 'Đang mở';

  @override
  String get keoStateFull => 'Đủ người';

  @override
  String get keoStatePlanning => 'Đang lên kế hoạch';

  @override
  String get keoStateConfirmed => 'Đã chốt';

  @override
  String get bookingPickGateway => 'Chọn cổng thanh toán';

  @override
  String get bookingNotConfigured => 'Cổng thanh toán chưa được cấu hình';

  @override
  String get bookingCreateError => 'Không tạo được thanh toán';

  @override
  String get planStatusConfirmed => 'Đã chốt';

  @override
  String get planStatusProposed => 'Chờ đồng ý';

  @override
  String get planVenuePicked => 'Quán đã chọn';

  @override
  String get planTitle => 'Kế hoạch';

  @override
  String get planLoadError => 'Không tải được kế hoạch';

  @override
  String get planNoVenuesTitle => 'Chưa có quán gợi ý';

  @override
  String get planNoVenuesSub =>
      'Khi có dữ liệu quán từ Places hoặc seed, bản đồ sẽ hiển thị marker để chọn điểm hẹn.';

  @override
  String get planReload => 'Tải lại';

  @override
  String get planVenuesLoadError => 'Không tải được danh sách quán';

  @override
  String planTime(String time) {
    return 'Thời gian: $time';
  }

  @override
  String planStatus(String status) {
    return 'Trạng thái: $status';
  }

  @override
  String get planConfirmCta => 'Đồng ý kế hoạch';

  @override
  String get planConfirmError => 'Không đồng ý được';

  @override
  String get planMapError => 'Không mở được bản đồ';

  @override
  String get planDirections => 'Chỉ đường';

  @override
  String planSuggestReason(String band) {
    return 'Gợi ý vì gần điểm cân bằng cả nhóm · cách $band km';
  }

  @override
  String get planPickVenue => 'Chọn quán này';

  @override
  String get planProposed => 'Đã đề xuất kế hoạch';

  @override
  String get planProposeError => 'Không đề xuất được';

  @override
  String get planPickSchedule => 'Chọn lịch hát';

  @override
  String get planOtherTime => 'Giờ khác';

  @override
  String get planProposeCta => 'Đề xuất kế hoạch';

  @override
  String get safetyShare => 'Chia sẻ cho bạn bè';

  @override
  String safetyShareMessage(String link) {
    return 'Mình đi hát, đây là kế hoạch: $link';
  }

  @override
  String get safetyShareError => 'Không tạo được link chia sẻ';

  @override
  String get safetyArrived => 'Tôi đã tới';

  @override
  String get safetyArrivedOk => 'Đã ghi nhận bạn đã tới';

  @override
  String get safetyArrivedError => 'Không ghi nhận được';

  @override
  String get planSharedTitle => 'Kế hoạch được chia sẻ';

  @override
  String get planSharedNotFound => 'Không tìm thấy kế hoạch';

  @override
  String get planMidpointMarker => 'Điểm giữa nhóm';

  @override
  String get planTomorrow => 'Mai';

  @override
  String get planWeekdaysShort => 'T2,T3,T4,T5,T6,T7,CN';

  @override
  String get settingsSectionPrivacy => 'Quyền riêng tư';

  @override
  String get settingsSectionData => 'Dữ liệu của tôi';

  @override
  String get settingsSectionAccount => 'Tài khoản';

  @override
  String get settingsSignOut => 'Đăng xuất';

  @override
  String get settingsSectionLegal => 'Pháp lý';

  @override
  String get settingsTerms => 'Điều khoản';

  @override
  String get settingsExportError => 'Không thể tải dữ liệu. Vui lòng thử lại.';

  @override
  String get settingsDeleteError => 'Không xoá được tài khoản, thử lại.';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get storeProDesc =>
      'Tạo kèo, tham gia không giới hạn và mở mọi tính năng trả phí.';

  @override
  String get storeBoostDesc => 'Đưa kèo của bạn lên đầu bảng trong 24 giờ.';

  @override
  String get storeSeeLikesDesc => 'Mở khóa danh sách người đã thả tim bạn.';

  @override
  String get storeFiltersDesc =>
      'Lọc theo gu nhạc, độ tuổi, khu vực và trạng thái hoạt động.';

  @override
  String get storeHeroSub =>
      'Mở khóa các công cụ giúp kèo lên nhanh và đúng người.';

  @override
  String get storeOpenError => 'Không mở được cửa hàng. Thử lại sau.';

  @override
  String get storeLoadError => 'Không tải được cửa hàng';

  @override
  String get photoLoadError => 'Không tải được ảnh. Thử lại nhé.';

  @override
  String get photoDeleteTitle => 'Xoá ảnh này?';

  @override
  String get photoDeleteBody => 'Ảnh sẽ bị gỡ khỏi hồ sơ của bạn.';

  @override
  String get photoDeleteError => 'Không xoá được ảnh. Thử lại nhé.';

  @override
  String photoSubMax(int max) {
    return 'Thêm tối đa $max ảnh để hồ sơ nổi bật hơn.';
  }

  @override
  String get photoConsentNeeded => 'Bật đồng ý dùng ảnh để thêm ảnh vào hồ sơ.';

  @override
  String get photoConsentCta => 'Bật trong Cài đặt';

  @override
  String promptMax(int max) {
    return 'Tối đa $max thẻ';
  }

  @override
  String promptSubMax(int max) {
    return 'Chọn tối đa $max câu để hồ sơ có chuyện mà bắt.';
  }

  @override
  String get promptAnswerHint => 'Câu trả lời của bạn…';

  @override
  String get adminActionFailed => 'Thao tác thất bại';

  @override
  String get adminTitle => 'Kiểm duyệt';

  @override
  String get adminEmpty => 'Không có báo cáo nào';

  @override
  String get adminHide => 'Ẩn';

  @override
  String get adminRemove => 'Gỡ';

  @override
  String get adminDismiss => 'Bỏ qua';

  @override
  String get adminLoadError => 'Không tải được báo cáo';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLangSystem => 'Theo hệ thống';

  @override
  String get locationPermissionTitle => 'Cần quyền vị trí';

  @override
  String get locationPermissionSub =>
      'Cho phép truy cập vị trí để tìm bạn hát và kèo quanh bạn.';

  @override
  String get locationOpenSettings => 'Mở cài đặt';

  @override
  String get locationServiceOffTitle => 'Định vị đang tắt';

  @override
  String get locationServiceOffSub => 'Bật định vị (GPS) rồi thử lại.';

  @override
  String get locationNoFixTitle => 'Không lấy được vị trí';

  @override
  String get locationNoFixSub =>
      'Không bắt được tín hiệu định vị — thử lại sau giây lát.';

  @override
  String get locationPushFailedTitle => 'Không gửi được vị trí';

  @override
  String get onbPhotosTitle => 'Thêm ảnh';

  @override
  String get onbPhotosSubOptional =>
      'Không bắt buộc — bạn có thể bổ sung hoặc đổi ảnh bất cứ lúc nào trong Hồ sơ.';

  @override
  String get onbPhotosDone => 'Xong';

  @override
  String get onbPhotosSkip => 'Để sau';
}
