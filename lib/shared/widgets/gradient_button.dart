import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

class GradientButton extends StatelessWidget {
  GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.height = AppSpacing.buttonHeight,
    LinearGradient? gradient,
  }) : gradient = gradient ?? AppColors.brandGradient;

  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final double height;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    // [AUDIT 2026-07-25] Trước đây: Opacity(0.56) + chữ trắng trên surfaceMuted
    // → nhãn nút đạt 1.23:1, không đọc nổi. WCAG miễn trừ control disabled nên
    // audit tự động không bắt, nhưng người dùng vẫn cần biết nút đó viết gì.
    // Nay: bỏ Opacity, dùng chữ ink trên surfaceMuted (8.55:1) và bỏ shadow —
    // trạng thái disabled đã được báo bằng nền xỉn + mất shadow + mất gradient.
    final foreground = enabled ? AppColors.onPrimary : AppColors.onDisabled;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: enabled ? [AppShadows.hard] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: DefaultTextStyle.merge(
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        // KHÔNG hạ cỡ này xuống dưới onPrimaryMinBoldSize:
                        // trắng trên cam chỉ đạt 3.75:1, chỉ hợp lệ khi được
                        // tính là "chữ lớn" (bold ≥18.66px). Xem
                        // AppColors.onPrimary và test/theme/color_contrast_test.dart.
                        fontSize: AppColors.onPrimaryMinBoldSize,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
