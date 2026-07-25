import 'package:flutter/material.dart';

/// Warm paper, citrus, and ink palette for the retro mixtape interface.
///
/// Mọi tỉ lệ tương phản ghi trong file này được kiểm tra tự động bởi
/// `test/theme/color_contrast_test.dart` — sửa hex mà quên cập nhật sẽ fail CI.
abstract final class AppColors {
  static const primary = Color(0xFFE8501F);
  static const primaryDark = Color(0xFF942D0E);
  static const primaryTint = Color(0xFFF8C9B8);
  static const primarySoft = Color(0xFFF18D69);

  /// CẢNH BÁO — trắng trên [primary] chỉ đạt **3.75:1**.
  ///
  /// Theo WCAG 1.4.3 tỉ lệ này CHỈ hợp lệ khi chữ được tính là "chữ lớn":
  /// ≥24px thường hoặc **≥18.66px bold**. Vì vậy chữ trắng trên nền cam
  /// bắt buộc dùng cỡ ≥ [onPrimaryMinBoldSize] và weight ≥ w700.
  /// Ở 16px bold (giá trị MASTER.md ghi sai trước 2026-07-25) tỉ lệ cần là
  /// 4.5:1 → TRƯỢT. [GradientButton] đã hardcode 19px/w700 nên đang đạt.
  ///
  /// Không dùng [ink] làm chữ trên [primary]: chỉ 3.29:1.
  /// Không dùng [primary] làm màu CHỮ trên nền giấy: chỉ 3.27:1.
  static const onPrimary = Color(0xFFFFFFFF);

  /// Cỡ chữ bold tối thiểu cho chữ trắng đặt trên [primary]. Xem [onPrimary].
  static const onPrimaryMinBoldSize = 19.0;

  /// Chữ cho control đang disabled (đặt trên [surfaceMuted] → 8.55:1).
  /// KHÔNG dùng [onPrimary] trắng cho state này: chỉ 1.44:1, không đọc được.
  static const onDisabled = ink;

  static const secondary = Color(0xFFC6E534);
  static const secondaryDark = Color(0xFF506100);
  static const secondaryTint = Color(0xFFEDF6B7);

  static const teal = Color(0xFF8FD8C8);

  /// Compatibility aliases retained for existing consumers.
  static const tertiary = teal;
  static const cyan = teal;
  static const tertiaryTint = Color(0xFFDDF3EE);
  static const tertiaryPop = Color(0xFF5DBBA8);

  static const pink = Color(0xFFE979A9);

  static const background = Color(0xFFF7EFD8);
  static const surface = Color(0xFFFCF6E3);
  static const surfaceAlt = Color(0xFFEFE4C8);
  static const surfaceWarm = Color(0xFFFADBC7);
  static const surfaceMuted = Color(0xFFE2D6B9);

  static const ink = Color(0xFF1E3A2F);
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF405B50);
  static const textHint = Color(0xFF5C7168);
  static const border = ink;

  static const success = Color(0xFF287A56); // 4.56:1 trên background
  static const successTint = Color(0xFFDDF1E7);

  /// 5.02:1 trên background. Trước 2026-07-25 là `0xFFA65B00` = 4.44:1 —
  /// trượt ngưỡng 4.5:1 đúng 0.06, đủ để fail audit nhưng khó thấy bằng mắt.
  static const warning = Color(0xFF9A5400);
  static const warningTint = Color(0xFFFFE8BF);
  static const error = Color(0xFFB42318); // 5.73:1 trên background
  static const errorTint = Color(0xFFFAD7D3);

  /// Nền CTA chính. Hai stop bằng nhau — giữ kiểu [LinearGradient] để
  /// [GradientButton] không phải đổi API, nhưng thực chất là màu đặc.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primary],
  );

  /// CHỈ dùng cho mảng trang trí — KHÔNG đặt chữ lên trên.
  ///
  /// Gradient chạy cam → lime. Chữ trắng ở đầu lime chỉ **1.43:1**, chữ ink ở
  /// đầu cam chỉ **3.29:1** — không có màu chữ nào an toàn trên cả dải.
  /// Nếu cần nút gradient thì đổi stop cuối sang một sắc cam đậm hơn.
  @Deprecated(
    'Không có màu chữ nào đạt 4.5:1 trên toàn dải cam→lime. '
    'Dùng brandGradient cho nút, hoặc chỉ dùng warmGradient làm nền trang trí.',
  )
  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const shadow = ink;
}
