import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Màn hình chúc mừng "match" toàn màn hình — hai monogram bay vào từ hai
/// bên, trái tim phóng to ở giữa, tiêu đề scale-in, và mưa nốt nhạc rơi nền.
/// Tôn trọng reduced-motion: nếu bật, nhảy thẳng tới trạng thái cuối.
class MatchCelebration extends StatefulWidget {
  const MatchCelebration({
    super.key,
    required this.otherName,
    required this.myName,
    required this.sharedBaitu,
    required this.onChat,
    required this.onContinue,
  });

  final String otherName;
  final String myName;
  final List<String> sharedBaitu;
  final VoidCallback onChat;
  final VoidCallback onContinue;

  @override
  State<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends State<MatchCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late final Animation<double> _titleIn;
  late final Animation<double> _rain;

  bool _reducedMotionHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _slide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
    );
    _titleIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
    );
    _rain = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1),
    );
    HapticFeedback.mediumImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotionHandled) return;
    _reducedMotionHandled = true;
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _monogram(String name) =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rain,
                  builder: (context, _) => CustomPaint(
                    painter: _NoteRainPainter(progress: _rain.value),
                  ),
                ),
              ),
              Column(
                children: [
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _slide,
                    builder: (context, child) {
                      final t = _slide.value.clamp(0.0, 1.0);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(-160 * (1 - t), 0),
                            child: _Monogram(letter: _monogram(widget.myName)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            child: Transform.scale(
                              scale: t,
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.onPrimary,
                                size: 40,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(160 * (1 - t), 0),
                            child:
                                _Monogram(letter: _monogram(widget.otherName)),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ScaleTransition(
                    scale: _titleIn,
                    child: FadeTransition(
                      opacity: _titleIn,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl),
                        child: Column(
                          children: [
                            Text(
                              'Hợp cạ rồi!',
                              textAlign: TextAlign.center,
                              style: AppTypography.display(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Bạn và ${widget.otherName} đã thích nhau',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                                fontSize: 15,
                              ),
                            ),
                            if (widget.sharedBaitu.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.onPrimary
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill),
                                ),
                                child: Text(
                                  'Cùng tủ: '
                                  '${widget.sharedBaitu.take(2).join(' · ')}',
                                  style: const TextStyle(
                                    color: AppColors.onPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      0,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('match_chat_btn'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.onPrimary,
                              foregroundColor: AppColors.primaryDark,
                            ),
                            onPressed: widget.onChat,
                            icon: const Icon(Icons.chat_bubble_rounded),
                            label: const Text('Nhắn tin ngay'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          key: const Key('match_continue_btn'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.onPrimary,
                          ),
                          onPressed: widget.onContinue,
                          child: const Text('Tiếp tục khám phá'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.onPrimary.withValues(alpha: 0.22),
        border: Border.all(color: AppColors.onPrimary, width: 2),
      ),
      child: Text(
        letter,
        style: AppTypography.display(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

/// Vẽ ~18 nốt nhạc rơi từ trên xuống, vị trí xác định (seeded) để không
/// nhấp nháy giữa các frame rebuild.
class _NoteRainPainter extends CustomPainter {
  _NoteRainPainter({required this.progress});

  final double progress;
  static const _count = 18;

  /// Hằng số per-note + TextPainter đã layout, tính MỘT LẦN thay vì 18
  /// allocation + layout mỗi frame. xFrac lưu ở dạng 0..1 vì x thực = xFrac *
  /// size.width chỉ biết được lúc paint. Thứ tự rút Random(42) phải y hệt vòng
  /// paint cũ (seed → xFrac → alpha → fontSize) để mỗi note ra đúng giá trị cũ,
  /// giữ output byte-identical.
  static final List<
      ({double xFrac, double seed, double alpha, double fontSize, TextPainter painter})>
  _notes = _buildNotes();

  static List<
      ({double xFrac, double seed, double alpha, double fontSize, TextPainter painter})>
  _buildNotes() {
    final random = Random(42);
    return List.generate(_count, (_) {
      final seed = random.nextDouble();
      final xFrac = random.nextDouble();
      final alpha = (0.15 + 0.55 * random.nextDouble()).clamp(0.0, 1.0);
      final fontSize = 14.0 + random.nextDouble() * 14;
      final painter = TextPainter(
        text: TextSpan(
          text: '♪',
          style: TextStyle(
            color: AppColors.onPrimary.withValues(alpha: alpha),
            fontSize: fontSize,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      return (
        xFrac: xFrac,
        seed: seed,
        alpha: alpha,
        fontSize: fontSize,
        painter: painter,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    for (final note in _notes) {
      final x = note.xFrac * size.width;
      final yFrac = (progress * (0.6 + note.seed)) % 1.2;
      final y = yFrac * size.height;
      note.painter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _NoteRainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
