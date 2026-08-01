import 'package:flutter/material.dart';

/// Một bảng màu trọn vẹn của hệ retro mixtape.
///
/// [AppColors] là mặt tiền tĩnh mà toàn bộ widget gọi; class này là dữ liệu
/// phía sau — hai bảng [light] (giấy kem ban ngày, giữ nguyên giá trị lịch sử)
/// và [dark] ("retro mixtape đêm": nền ink sẫm ánh rêu, chữ/viền kem, cam CTA
/// giữ nguyên). `test/theme/color_contrast_test.dart` chạy trên CẢ HAI bảng —
/// đổi hex ở đây mà quên chạy test là CI chặn.
///
/// Vai trò của từng màu xem doc ở [AppColors]; file này chỉ là số.
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryTint,
    required this.primarySoft,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryDark,
    required this.secondaryTint,
    required this.teal,
    required this.tertiaryTint,
    required this.tertiaryPop,
    required this.pink,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceWarm,
    required this.surfaceMuted,
    required this.ink,
    required this.textSecondary,
    required this.textHint,
    required this.success,
    required this.successTint,
    required this.warning,
    required this.warningTint,
    required this.error,
    required this.errorTint,
    required this.hardShadow,
    required this.scrim,
  });

  final Color primary;

  /// Light: sắc cam ĐẬM (nền badge chữ trắng + chữ cam trên nền giấy).
  /// Dark: sắc cam SÁNG (đào) — cùng vai trò "cam đạt 4.5:1 làm chữ trên nền",
  /// nhưng KHÔNG còn chịu được chữ trắng (xem test per-palette).
  final Color primaryDark;
  final Color primaryTint;
  final Color primarySoft;
  final Color onPrimary;
  final Color secondary;

  /// Cùng khuôn [primaryDark]: light = olive đậm, dark = olive sáng vừa đủ
  /// giữ cả hai ràng buộc WaveProgress (3:1 vs nền và vs surfaceMuted).
  final Color secondaryDark;
  final Color secondaryTint;
  final Color teal;
  final Color tertiaryTint;
  final Color tertiaryPop;
  final Color pink;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceWarm;
  final Color surfaceMuted;

  /// Chữ + viền + icon. Light = xanh ink; dark = kem dịu (chính giấy kem
  /// hạ sáng một nấc để đỡ chói OLED).
  final Color ink;
  final Color textSecondary;
  final Color textHint;
  final Color success;
  final Color successTint;
  final Color warning;
  final Color warningTint;
  final Color error;
  final Color errorTint;

  /// Màu cho [AppShadows.hard] (đổ bóng cứng offset 3,3).
  final Color hardShadow;
  final Color scrim;

  static const light = AppPalette(
    primary: Color(0xFFE8501F),
    primaryDark: Color(0xFF942D0E),
    primaryTint: Color(0xFFF8C9B8),
    primarySoft: Color(0xFFF18D69),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC6E534),
    secondaryDark: Color(0xFF506100),
    secondaryTint: Color(0xFFEDF6B7),
    teal: Color(0xFF8FD8C8),
    tertiaryTint: Color(0xFFDDF3EE),
    tertiaryPop: Color(0xFF5DBBA8),
    pink: Color(0xFFE979A9),
    background: Color(0xFFF7EFD8),
    surface: Color(0xFFFCF6E3),
    surfaceAlt: Color(0xFFEFE4C8),
    surfaceWarm: Color(0xFFFADBC7),
    surfaceMuted: Color(0xFFE2D6B9),
    ink: Color(0xFF1E3A2F),
    textSecondary: Color(0xFF405B50),
    textHint: Color(0xFF5C7168),
    success: Color(0xFF287A56),
    successTint: Color(0xFFDDF1E7),
    warning: Color(0xFF9A5400),
    warningTint: Color(0xFFFFE8BF),
    error: Color(0xFFB42318),
    errorTint: Color(0xFFFAD7D3),
    hardShadow: Color(0x331E3A2F),
    scrim: Color(0x991E3A2F),
  );

  /// "Retro mixtape đêm". Hex ở đây là giá trị ĐÃ qua contrast test — chỉnh
  /// gì cũng phải chạy lại `flutter test test/theme/`.
  static const dark = AppPalette(
    primary: Color(0xFFE8501F),
    primaryDark: Color(0xFFFFB59B),
    primaryTint: Color(0xFF4A2417),
    primarySoft: Color(0xFFF18D69),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC6E534),
    secondaryDark: Color(0xFFA9C42F),
    secondaryTint: Color(0xFF333D12),
    teal: Color(0xFF8FD8C8),
    tertiaryTint: Color(0xFF1F3A34),
    tertiaryPop: Color(0xFF5DBBA8),
    pink: Color(0xFFE979A9),
    background: Color(0xFF14231C),
    surface: Color(0xFF1B2E25),
    surfaceAlt: Color(0xFF24382C),
    surfaceWarm: Color(0xFF3A2E24),
    surfaceMuted: Color(0xFF2E4237),
    ink: Color(0xFFF2EAD3),
    textSecondary: Color(0xFFB7C7BB),
    textHint: Color(0xFF93A79A),
    success: Color(0xFF58C389),
    successTint: Color(0xFF163326),
    warning: Color(0xFFD99A3D),
    warningTint: Color(0xFF3A2E14),
    error: Color(0xFFEF6A5E),
    errorTint: Color(0xFF45201C),
    hardShadow: Color(0x8C000000),
    scrim: Color(0xCC000000),
  );
}
