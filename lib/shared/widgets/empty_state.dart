import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'gradient_button.dart';

/// Friendly empty/placeholder state: round icon + title + subtitle + optional CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final hardSurface = BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.ink, width: 2),
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      boxShadow: <BoxShadow>[AppShadows.hard],
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: hardSurface,
          child: Icon(icon, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: AppSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            title,
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              subtitle!,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          GradientButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
        if (secondaryActionLabel != null && onSecondaryAction != null) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onSecondaryAction,
            child: Text(secondaryActionLabel!),
          ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: reduceMotion
            ? content
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppMotion.slow,
                curve: AppMotion.enterCurve,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - t)),
                    child: child,
                  ),
                ),
                child: content,
              ),
      ),
    );
  }
}
