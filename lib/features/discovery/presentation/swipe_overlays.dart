import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Bọc ngoài CandidateCard trong CardSwiper.cardBuilder. Stamp mờ dần theo
/// tiến độ kéo — đúng cơ chế deck app hẹn hò: người dùng thấy trước hệ quả
/// của cú vuốt đang thực hiện.
class SwipeOverlays extends StatelessWidget {
  const SwipeOverlays({
    super.key,
    required this.hProgress, // -1..1, dương = kéo phải (thích)
    required this.vProgress, // -1..1, âm = kéo lên (siêu thích)
    required this.child,
  });

  final double hProgress;
  final double vProgress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final like = hProgress.clamp(0.0, 1.0);
    final nope = (-hProgress).clamp(0.0, 1.0);
    // Kéo chéo: ưu tiên hướng ngang — siêu thích chỉ rõ khi kéo thẳng lên.
    final superLike =
        ((-vProgress).clamp(0.0, 1.0) * (1 - hProgress.abs()).clamp(0.0, 1.0));

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        _Stamp(
          opacityKey: const Key('overlay_like'),
          label: 'THÍCH',
          color: AppColors.success,
          opacity: like,
          alignment: Alignment.topLeft,
          angle: -0.25,
        ),
        _Stamp(
          opacityKey: const Key('overlay_nope'),
          label: 'BỎ QUA',
          color: AppColors.error,
          opacity: nope,
          alignment: Alignment.topRight,
          angle: 0.25,
        ),
        _Stamp(
          opacityKey: const Key('overlay_super'),
          label: 'SIÊU THÍCH',
          color: AppColors.tertiary,
          opacity: superLike,
          alignment: Alignment.bottomCenter,
          angle: -0.12,
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.opacityKey,
    required this.label,
    required this.color,
    required this.opacity,
    required this.alignment,
    required this.angle,
  });

  final Key opacityKey;
  final String label;
  final Color color;
  final double opacity;
  final Alignment alignment;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      key: opacityKey,
      opacity: opacity,
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Transform.rotate(
              angle: angle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: AppTypography.display(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
