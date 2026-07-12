import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fixed waveform silhouette (0..1 of the available height) for
/// [WaveProgress]. A constant list keeps the bar pattern stable across
/// rebuilds — no Random() call in paint.
const List<double> _kWaveProgressBarHeights = <double>[
  0.42, 0.68, 0.92, 0.55, 0.30, 0.74, 0.98, 0.46,
  0.64, 0.34, 0.84, 0.58, 0.94, 0.40, 0.70, 0.36,
  0.80, 0.50, 0.90, 0.38, 0.62, 0.96, 0.48, 0.72,
  0.32, 0.82, 0.54, 0.66,
];

/// A waveform-styled "profile completion" meter (mockup 18): a row of
/// vertical bars where the bars up to [progress] are tinted ink-green and
/// the remaining bars stay muted.
class WaveProgress extends StatelessWidget {
  const WaveProgress({super.key, required this.progress})
    : assert(progress >= 0 && progress <= 1, 'progress must be within 0..1.');

  /// Completion ratio, 0..1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Semantics(
      label: 'Hồ sơ hoàn thiện $percent%',
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: CustomPaint(painter: WaveProgressPainter(progress: progress)),
      ),
    );
  }
}

/// Draws the fixed-pattern bar waveform, tinting bars up to [progress].
class WaveProgressPainter extends CustomPainter {
  const WaveProgressPainter({required this.progress});

  final double progress;

  static final _barCount = _kWaveProgressBarHeights.length;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final donePaint = Paint()
      ..color = AppColors.secondaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final todoPaint = Paint()
      ..color = AppColors.surfaceMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final slot = size.width / _barCount;
    for (var i = 0; i < _barCount; i++) {
      final x = slot * i + slot / 2;
      final barHeight = size.height * _kWaveProgressBarHeights[i];
      final top = (size.height - barHeight) / 2;
      final bottom = top + barHeight;
      final isDone = (i / _barCount) <= progress;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        isDone ? donePaint : todoPaint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveProgressPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
