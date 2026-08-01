import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Warm paper, citrus, and ink palette for the retro mixtape interface.
///
/// [DARK] Từ 2026-08-01 đây là MẶT TIỀN đọc bảng màu hiện hành: hai bảng
/// nằm ở [AppPalette] (light/dark), [select] được `CungHatApp.build` gọi
/// TRƯỚC khi dựng MaterialApp nên mọi widget build sau đó đọc đúng bảng.
/// Giữ nguyên tên member để không phải sửa hàng trăm call-site; giá phải trả
/// là các widget `const` dùng màu đã phải bỏ `const` (compiler liệt kê).
///
/// Mọi tỉ lệ tương phản ghi trong file này được kiểm tra tự động bởi
/// `test/theme/color_contrast_test.dart` — CHO CẢ HAI bảng màu.
abstract final class AppColors {
  static AppPalette _p = AppPalette.light;

  /// Bảng màu đang hiệu lực — cho test và các builder cần trọn bảng.
  static AppPalette get palette => _p;

  /// Chọn bảng theo brightness hiệu lực. Widget test mặc định light;
  /// test dark gọi tay + `addTearDown(() => AppColors.select(Brightness.light))`.
  static void select(Brightness b) =>
      _p = b == Brightness.dark ? AppPalette.dark : AppPalette.light;

  static Color get primary => _p.primary;
  static Color get primaryDark => _p.primaryDark;
  static Color get primaryTint => _p.primaryTint;
  static Color get primarySoft => _p.primarySoft;

  /// CẢNH BÁO — trắng trên [primary] chỉ đạt **3.75:1** (cả hai mode: cặp
  /// trắng/cam không phụ thuộc nền).
  ///
  /// Theo WCAG 1.4.3 tỉ lệ này CHỈ hợp lệ khi chữ được tính là "chữ lớn":
  /// ≥24px thường hoặc **≥18.66px bold**. Vì vậy chữ trắng trên nền cam
  /// bắt buộc dùng cỡ ≥ [onPrimaryMinBoldSize] và weight ≥ w700.
  ///
  /// Không dùng [ink] làm chữ trên [primary]. Không dùng [primary] làm màu
  /// CHỮ nhỏ trên nền (light 3.27:1, dark 4.21:1 — đều dưới 4.5).
  static Color get onPrimary => _p.onPrimary;

  /// Cỡ chữ bold tối thiểu cho chữ trắng đặt trên [primary]. Xem [onPrimary].
  static const onPrimaryMinBoldSize = 19.0;

  /// Chữ cho control đang disabled (đặt trên [surfaceMuted]).
  static Color get onDisabled => ink;

  /// Chữ/icon đặt trên FILL ACCENT SÁNG (lime/teal/pink/primarySoft đặc).
  ///
  /// Các fill này giữ NGUYÊN hex ở cả hai mode, nên màu chữ trên chúng cũng
  /// cố định = ink của bảng light — KHÔNG dùng [ink] (dark mode ink là kem,
  /// kem trên lime chỉ ~1.2:1). Contrast test khoá cặp này cho cả 4 fill.
  static Color get onAccent => AppPalette.light.ink;

  static Color get secondary => _p.secondary;
  static Color get secondaryDark => _p.secondaryDark;
  static Color get secondaryTint => _p.secondaryTint;

  static Color get teal => _p.teal;

  /// Compatibility aliases retained for existing consumers.
  static Color get tertiary => teal;
  static Color get cyan => teal;
  static Color get tertiaryTint => _p.tertiaryTint;
  static Color get tertiaryPop => _p.tertiaryPop;

  static Color get pink => _p.pink;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceAlt => _p.surfaceAlt;
  static Color get surfaceWarm => _p.surfaceWarm;
  static Color get surfaceMuted => _p.surfaceMuted;

  static Color get ink => _p.ink;
  static Color get textPrimary => ink;
  static Color get textSecondary => _p.textSecondary;
  static Color get textHint => _p.textHint;
  static Color get border => ink;

  static Color get success => _p.success;
  static Color get successTint => _p.successTint;
  static Color get warning => _p.warning;
  static Color get warningTint => _p.warningTint;
  static Color get error => _p.error;
  static Color get errorTint => _p.errorTint;

  /// Nền CTA chính. Hai stop bằng nhau — giữ kiểu [LinearGradient] để
  /// [GradientButton] không phải đổi API, nhưng thực chất là màu đặc.
  static LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primary],
  );

  /// CHỈ dùng cho mảng trang trí — KHÔNG đặt chữ lên trên.
  @Deprecated(
    'Không có màu chữ nào đạt 4.5:1 trên toàn dải cam→lime. '
    'Dùng brandGradient cho nút, hoặc chỉ dùng warmGradient làm nền trang trí.',
  )
  static LinearGradient get warmGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static Color get shadow => ink;
}
