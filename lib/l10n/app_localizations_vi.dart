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
}
