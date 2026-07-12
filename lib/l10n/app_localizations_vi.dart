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
}
