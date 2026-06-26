import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Wordmark + round icon used on auth/landing screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.tagline});
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
              color: AppColors.primaryTint, shape: BoxShape.circle),
          child: const Icon(Icons.mic_external_on, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Cùng Hát',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary)),
        if (tagline != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(tagline!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
