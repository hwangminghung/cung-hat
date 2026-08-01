import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// Bề mặt card retro: nền kem, viền ink 2px, bóng cứng offset(3,3).
///
/// Thay cho `Card` Material ở các bề mặt nổi — elevation của Card không tạo
/// được bóng lệch góc theo design system. Nội dung luôn được clip theo bo góc
/// (ảnh full-bleed an toàn); màu nền đặt trên [Material] để ink/splash của
/// ListTile bên trong vẽ đúng lớp.
class HardCard extends StatelessWidget {
  HardCard({
    super.key,
    required this.child,
    Color? color,
    this.margin = EdgeInsets.zero,
  }) : color = color ?? AppColors.surface;

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusCard);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [AppShadows.hard],
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AppColors.border, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
