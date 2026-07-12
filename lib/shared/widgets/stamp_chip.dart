import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Approved fill choices for [StampChip].
enum StampChipTone { lime, teal }

/// A compact, non-interactive retro stamp for status and music labels.
class StampChip extends StatelessWidget {
  const StampChip({
    super.key,
    required this.label,
    this.tone = StampChipTone.lime,
    this.leadingIcon,
  });

  final String label;
  final StampChipTone tone;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (tone) {
      StampChipTone.lime => AppColors.secondary,
      StampChipTone.teal => AppColors.teal,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 16, color: AppColors.ink),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
