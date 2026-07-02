import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Bọc ngoài CandidateCard trong CardSwiper.cardBuilder. Stamp mờ dần theo
/// tiến độ kéo — đúng cơ chế deck app hẹn hò: người dùng thấy trước hệ quả
/// của cú vuốt đang thực hiện.
///
/// cardBuilder chạy mỗi frame kéo nên: (1) stamp ẩn (opacity <= 0) không
/// được build; (2) phần nhìn tĩnh của stamp (khung + chữ, gồm cả resolve
/// TextStyle qua GoogleFonts) được build đúng một lần vào static final;
/// (3) card được bọc RepaintBoundary để không phải vẽ lại khi chỉ stamp đổi.
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

  static final Widget _likeContent =
      _stampContent('THÍCH', AppColors.success);
  static final Widget _nopeContent =
      _stampContent('BỎ QUA', AppColors.error);
  static final Widget _superContent =
      _stampContent('SIÊU THÍCH', AppColors.tertiary);

  static Widget _stampContent(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
      );

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
        RepaintBoundary(child: child),
        if (like > 0)
          _Stamp(
            stampKey: const Key('overlay_like'),
            opacity: like,
            alignment: Alignment.topLeft,
            angle: -0.25,
            child: _likeContent,
          ),
        if (nope > 0)
          _Stamp(
            stampKey: const Key('overlay_nope'),
            opacity: nope,
            alignment: Alignment.topRight,
            angle: 0.25,
            child: _nopeContent,
          ),
        if (superLike > 0)
          _Stamp(
            stampKey: const Key('overlay_super'),
            opacity: superLike,
            alignment: Alignment.bottomCenter,
            angle: -0.12,
            child: _superContent,
          ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.stampKey,
    required this.opacity,
    required this.alignment,
    required this.angle,
    required this.child,
  });

  final Key stampKey;
  final double opacity;
  final Alignment alignment;
  final double angle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      key: stampKey,
      opacity: opacity,
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Transform.rotate(
              angle: angle,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
