import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.height = AppSpacing.buttonHeight,
    this.gradient = AppColors.brandGradient,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final double height;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: enabled ? const [AppShadows.hard] : null,
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
                      Icon(icon, color: AppColors.onPrimary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
