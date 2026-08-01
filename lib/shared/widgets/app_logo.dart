import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'wave_divider.dart';

/// Wordmark + "CH" squircle mark (with waveform) used on auth/landing screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.tagline});

  final String? tagline;

  /// Fixed mark size — the widget has no `size` param to preserve today's
  /// call-site layout (only `phone_screen.dart` uses AppLogo).
  static const double _markSize = 84;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          // Width stays fixed at the mark's target size so on-screen layout
          // matches today's 84x84 badge. Height is intentionally left to
          // the child's intrinsic size (mainAxisSize.min below) instead of
          // being pinned to _markSize too: text-line metrics for the Oswald
          // "CH" glyph vary across platforms/font-fallback (the headless
          // test runner in particular measures noticeably taller lines than
          // a real device), and pinning height caused a RenderFlex overflow
          // there. Auto height keeps the badge overflow-proof everywhere
          // while still rendering ~square on real devices.
          width: _markSize,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(_markSize * 0.28),
            boxShadow: [AppShadows.hard],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _markSize * 0.12,
              vertical: _markSize * 0.14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CH',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: _markSize * 0.42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: _markSize * 0.06),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: _markSize * 0.15),
                  child: WaveDivider(color: AppColors.primary),
                ),
              ],
            ),
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
