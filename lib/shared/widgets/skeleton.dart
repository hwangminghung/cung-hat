import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Shimmering placeholder block for loading states.
/// Prefer these over spinners for content that takes >300ms to load.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppSpacing.sm,
  });

  /// Circular avatar placeholder.
  const Skeleton.circle({super.key, double size = 48})
    : width = size,
      height = size,
      radius = size / 2;

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _controller.isAnimating) _controller.stop();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: const [
                AppColors.surfaceAlt,
                AppColors.border,
                AppColors.surfaceAlt,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ListTile-shaped skeleton (avatar + title + subtitle lines).
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Skeleton.circle(size: 44),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 140, height: 15),
                SizedBox(height: AppSpacing.sm),
                Skeleton(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card-shaped skeleton mimicking a list card (title + meta lines + chips).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: 180, height: 18),
            SizedBox(height: AppSpacing.md),
            Skeleton(width: 120, height: 24, radius: AppSpacing.radiusPill),
            SizedBox(height: AppSpacing.md),
            Skeleton(width: 220, height: 13),
            SizedBox(height: AppSpacing.sm),
            Skeleton(width: 160, height: 13),
          ],
        ),
      ),
    );
  }
}
