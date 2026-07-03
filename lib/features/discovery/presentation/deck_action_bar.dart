import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Hàng nút hành động dưới deck. Thuần UI — mọi logic (gate Pro, quota,
/// controller.swipe) do DoiDeckScreen quyết định qua callback.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({
    super.key,
    required this.onRewind,
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    required this.rewindEnabled,
  });

  final VoidCallback onRewind;
  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;

  /// false = user free: nút vẫn tap được nhưng mờ; caller mở Pro upsell.
  final bool rewindEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Opacity(
          opacity: rewindEnabled ? 1 : 0.45,
          child: _RoundButton(
            key: const Key('deck_rewind_btn'),
            icon: Icons.replay_rounded,
            color: AppColors.warning,
            size: 48,
            onTap: onRewind,
          ),
        ),
        _RoundButton(
          key: const Key('deck_pass_btn'),
          icon: Icons.close_rounded,
          color: AppColors.error,
          size: 62,
          onTap: onPass,
        ),
        _RoundButton(
          key: const Key('deck_super_btn'),
          icon: Icons.star_rounded,
          color: AppColors.tertiary,
          size: 48,
          onTap: onSuperLike,
        ),
        _RoundButton(
          key: const Key('deck_like_btn'),
          icon: Icons.favorite_rounded,
          color: AppColors.success,
          size: 62,
          onTap: onLike,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: CircleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      elevation: 2,
      shadowColor: AppColors.shadow.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, color: color, size: size * 0.5),
        ),
      ),
    );
  }
}
