import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A decorative audio-wave rule that expands to its parent's width.
class WaveDivider extends StatelessWidget {
  WaveDivider({
    super.key,
    this.height = AppSpacing.lg,
    Color? color,
    this.strokeWidth = 1.5,
  }) : color = color ?? AppColors.secondaryTint,
       assert(height > 0, 'height must be greater than zero.'),
       assert(strokeWidth > 0, 'strokeWidth must be greater than zero.');

  final double height;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
          painter: WaveDividerPainter(color: color, strokeWidth: strokeWidth),
        ),
      ),
    );
  }
}

/// Draws a centered, tapered waveform without contributing semantics.
class WaveDividerPainter extends CustomPainter {
  const WaveDividerPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final centerY = size.height / 2;
    final path = Path()..moveTo(0, centerY);
    const steps = 24;

    for (var step = 1; step <= steps; step++) {
      final progress = step / steps;
      final envelope = math.sin(math.pi * progress);
      final carrier = math.sin(math.pi * 6 * progress);
      path.lineTo(
        size.width * progress,
        centerY + (size.height * 0.32 * envelope * carrier),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(WaveDividerPainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}
