import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Hàng nút hành động dưới deck. Thuần UI — mọi logic (gate Pro, quota,
/// controller.swipe) do DoiDeckScreen quyết định qua callback.
///
/// [hProgress]/[vProgress] (-1..1, cùng đơn vị với [SwipeOverlays]) đồng bộ
/// hiệu ứng nhấn mạnh nút với chiều đang kéo card (Tinder-parity mục 3):
/// kéo phải → nút thích phóng to; kéo trái → nút bỏ qua; kéo lên → nút siêu
/// thích. Mặc định 0 (không kéo) → mọi nút ở scale bình thường.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({
    super.key,
    required this.onRewind,
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    required this.rewindEnabled,
    this.hProgress = 0,
    this.vProgress = 0,
  });

  final VoidCallback onRewind;
  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;

  /// false = user free: nút vẫn tap được nhưng mờ; caller mở Pro upsell.
  final bool rewindEnabled;

  final double hProgress;
  final double vProgress;

  @override
  Widget build(BuildContext context) {
    final passEmphasis = (-hProgress).clamp(0.0, 1.0);
    final likeEmphasis = hProgress.clamp(0.0, 1.0);
    final superEmphasis = (-vProgress).clamp(0.0, 1.0);

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
          emphasis: passEmphasis,
        ),
        _RoundButton(
          key: const Key('deck_super_btn'),
          icon: Icons.star_rounded,
          color: AppColors.tertiary,
          size: 48,
          onTap: onSuperLike,
          emphasis: superEmphasis,
        ),
        _RoundButton(
          key: const Key('deck_like_btn'),
          icon: Icons.favorite_rounded,
          color: AppColors.success,
          size: 62,
          onTap: onLike,
          emphasis: likeEmphasis,
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
    this.emphasis = 0.0,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  /// 0..1 — mức kéo theo chiều nút này đại diện. 0 = bình thường; 1 = đang
  /// kéo hết cỡ về hướng này (nút to hơn, viền đậm hơn, nền bắt đầu nhuốm màu).
  final double emphasis;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1 + 0.15 * emphasis,
      child: Material(
        color: Color.lerp(
            AppColors.surface, color.withValues(alpha: 0.18), emphasis)!,
        shape: CircleBorder(
          side: BorderSide(
              color: color.withValues(alpha: 0.35 + 0.65 * emphasis),
              width: 1.5 + emphasis),
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
      ),
    );
  }
}
