import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Deliberately rigid shadows used by retro surfaces and controls.
///
/// [DARK] Hết `const` từ 2026-08-01: màu bóng đọc theo bảng màu hiện hành
/// (light = ink 20%, dark = đen 55% — bóng ink trên nền tối gần như tàng
/// hình). Chỗ nào từng viết `const [AppShadows.hard]` đã phải bỏ const.
abstract final class AppShadows {
  static Color get hardColor => AppColors.palette.hardShadow;

  static BoxShadow get hard =>
      BoxShadow(color: hardColor, offset: const Offset(3, 3), blurRadius: 0);
}
