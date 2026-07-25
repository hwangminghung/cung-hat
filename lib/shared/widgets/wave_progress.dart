import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Fixed waveform silhouette (0..1 of the available height) for
/// [WaveProgress]. A constant list keeps the bar pattern stable across
/// rebuilds — no Random() call in paint.
const List<double> _kWaveProgressBarHeights = <double>[
  0.42,
  0.68,
  0.92,
  0.55,
  0.30,
  0.74,
  0.98,
  0.46,
  0.64,
  0.34,
  0.84,
  0.58,
  0.94,
  0.40,
  0.70,
  0.36,
  0.80,
  0.50,
  0.90,
  0.38,
  0.62,
  0.96,
  0.48,
  0.72,
  0.32,
  0.82,
  0.54,
  0.66,
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Semantics(
      label: l10n?.completionPercent(percent) ?? 'Hồ sơ hoàn thiện $percent%',
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

  /// Number of bars in the fixed waveform pattern.
  static final barCount = _kWaveProgressBarHeights.length;

  /// Whether bar [index] is painted as "done": only when its WHOLE slice
  /// fits inside [progress] — so 0.0 tints no bar (fresh profile) and 1.0
  /// tints every bar. `index / barCount` would mark bar 0 done even at 0.0.
  bool isBarDone(int index) => (index + 1) / barCount <= progress;

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

    final slot = size.width / barCount;
    for (var i = 0; i < barCount; i++) {
      final x = slot * i + slot / 2;
      final barHeight = size.height * _kWaveProgressBarHeights[i];
      final top = (size.height - barHeight) / 2;
      final bottom = top + barHeight;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        isBarDone(i) ? donePaint : todoPaint,
      );
    }

    _paintScale(canvas, size);
  }

  /// [AUDIT 2026-07-25] Thanh "chưa xong" dùng `surfaceMuted` chỉ đạt 1.26:1 so
  /// với nền giấy — người dùng thấy phần ĐÃ xong nhưng không thấy TỔNG chiều
  /// dài, nên 75% trông hệt 95%. Đây là widget duy nhất trong hệ vẽ trần bằng
  /// CustomPainter, không có viền ink 2px để gánh ranh giới (WCAG 1.4.11).
  ///
  /// Không đổi màu `surfaceMuted` cho đậm lên: làm vậy sẽ ăn mất tương phản
  /// giữa "đã xong" và "chưa xong" (đo được: đậm tới mức đạt 3:1 với nền thì
  /// tụt xuống 2.5:1 với thanh đã xong — đổi lỗi này lấy lỗi khác).
  ///
  /// Thay vào đó vẽ khung thang bằng ink (10.75:1): một đường nền mảnh cộng
  /// hai vạch chặn hai đầu — đúng ngôn ngữ ink của hệ, và giống mặt VU meter.
  void _paintScale(Canvas canvas, Size size) {
    final inkPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    final baseline = size.height - 1;
    canvas.drawLine(
      Offset(1, baseline),
      Offset(size.width - 1, baseline),
      inkPaint,
    );

    // Vạch chặn hai đầu — cận trên/dưới của thang, để 0% và 100% đọc được.
    const capHeight = 7.0;
    for (final x in <double>[1, size.width - 1]) {
      canvas.drawLine(
        Offset(x, baseline - capHeight),
        Offset(x, baseline),
        inkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveProgressPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
