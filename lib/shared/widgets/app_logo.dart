import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Wordmark + squircle mic mark used on auth/landing screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.tagline});

  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.20),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: 12,
                top: 12,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              Icon(
                Icons.mic_external_on_rounded,
                color: AppColors.onPrimary,
                size: 38,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Cùng Hát',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (tagline != null) ...[
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              tagline!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
