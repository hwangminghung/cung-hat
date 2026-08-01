import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../onboarding/application/reference_providers.dart';
import '../../onboarding/domain/music_ref.dart';

/// Màn hình chúc mừng "match" toàn màn hình — hai thẻ monogram bay vào từ hai
/// bên, tiêu đề scale-in, và mưa confetti/nốt nhạc retro chạy nền.
/// Tôn trọng reduced-motion: nếu bật, nhảy thẳng tới trạng thái cuối.
///
/// [sharedBaitu] giữ SONG ID thô — resolve tên hiển thị qua songsProvider
/// (cùng pattern CandidateDetailSheet); loading/lỗi/id lạ → raw id fallback.
class MatchCelebration extends ConsumerStatefulWidget {
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
  ConsumerState<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends ConsumerState<MatchCelebration>
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
    _rain = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1));
    HapticFeedback.mediumImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotionHandled) return;
    _reducedMotionHandled = true;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    // Đang loading/lỗi → map rỗng → fallback raw id, KHÔNG chặn màn ăn mừng;
    // watch nên khi songs resolve xong widget tự rebuild ra tên bài.
    final songs = ref.watch(songsProvider).value ?? const <Song>[];
    final titleById = {for (final s in songs) s.id: s.title};

    return Scaffold(
      key: const Key('screen_09_match_celebration'),
      backgroundColor: AppColors.background,
      body: Container(
        key: const Key('match_cream_surface'),
        decoration: const BoxDecoration(color: AppColors.background),
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n?.appTitle ?? 'Cùng Hát',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const WaveDivider(height: AppSpacing.xxl),
                          ScaleTransition(
                            scale: _titleIn,
                            child: FadeTransition(
                              opacity: _titleIn,
                              child: Column(
                                children: [
                                  Text(
                                    l10n?.celebrateTitle ?? 'Hợp cạ rồi!',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.display(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n?.celebrateBody(widget.otherName) ??
                                        'Bạn và ${widget.otherName} đã thích nhau',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AnimatedBuilder(
                            animation: _slide,
                            builder: (context, child) {
                              final t = _slide.value.clamp(0.0, 1.0);
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Transform.translate(
                                        offset: Offset(-160 * (1 - t), 0),
                                        child: Transform.rotate(
                                          angle: -0.07,
                                          child: _IdentityCard(
                                            cardKey: const Key(
                                              'match_identity_my',
                                            ),
                                            letter: _monogram(widget.myName),
                                            name: widget.myName,
                                            accent: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Transform.translate(
                                        offset: Offset(160 * (1 - t), 0),
                                        child: Transform.rotate(
                                          angle: 0.07,
                                          child: _IdentityCard(
                                            cardKey: const Key(
                                              'match_identity_other',
                                            ),
                                            letter: _monogram(widget.otherName),
                                            name: widget.otherName,
                                            accent: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Transform.scale(
                                    scale: t,
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.teal,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.ink,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.favorite_rounded,
                                        color: AppColors.ink,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const WaveDivider(height: AppSpacing.xxl),
                          if (widget.sharedBaitu.isNotEmpty)
                            StampChip(
                              leadingIcon: Icons.music_note_rounded,
                              label:
                                  l10n?.celebrateSharedBaitu(
                                    widget.sharedBaitu
                                        .take(2)
                                        .map((id) => titleById[id] ?? id)
                                        .join(' · '),
                                  ) ??
                                  'Cùng tủ: ${widget.sharedBaitu.take(2).map((id) => titleById[id] ?? id).join(' · ')}',
                              tone: StampChipTone.teal,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            key: const Key('match_chat_btn'),
                            onPressed: widget.onChat,
                            icon: Icons.chat_bubble_rounded,
                            child: Text(
                              l10n?.celebrateChatNow ?? 'Nhắn tin ngay',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          key: const Key('match_continue_btn'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            textStyle: const TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.secondaryDark,
                              decorationThickness: 2,
                            ),
                          ),
                          onPressed: widget.onContinue,
                          child: Text(
                            l10n?.celebrateContinue ?? 'Tiếp tục khám phá',
                          ),
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.cardKey,
    required this.letter,
    required this.name,
    required this.accent,
  });

  final Key cardKey;
  final String letter;
  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      width: 140,
      height: 150,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [AppShadows.hard],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard - 4),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: Text(
                letter,
                style: AppTypography.display(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: accent == AppColors.primary
                      ? AppColors.onPrimary
                      : AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name.trim().isEmpty ? '?' : name.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
  static const _palette = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.teal,
  ];

  /// Hằng số per-note + TextPainter đã layout, tính MỘT LẦN thay vì 18
  /// allocation + layout mỗi frame. xFrac lưu ở dạng 0..1 vì x thực = xFrac *
  /// size.width chỉ biết được lúc paint. Thứ tự rút Random(42) phải y hệt vòng
  /// paint cũ (seed → xFrac → alpha → fontSize) để mỗi note ra đúng giá trị cũ,
  /// giữ output byte-identical.
  static final List<
    ({
      double xFrac,
      double seed,
      double alpha,
      double fontSize,
      TextPainter painter,
    })
  >
  _notes = _buildNotes();

  static List<
    ({
      double xFrac,
      double seed,
      double alpha,
      double fontSize,
      TextPainter painter,
    })
  >
  _buildNotes() {
    final random = Random(42);
    return List.generate(_count, (index) {
      final seed = random.nextDouble();
      final xFrac = random.nextDouble();
      final alpha = (0.15 + 0.55 * random.nextDouble()).clamp(0.0, 1.0);
      final fontSize = 14.0 + random.nextDouble() * 14;
      final painter = TextPainter(
        text: TextSpan(
          text: '♪',
          style: TextStyle(
            color: _palette[index % _palette.length].withValues(alpha: alpha),
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
    for (final (index, note) in _notes.indexed) {
      final x = note.xFrac * size.width;
      final yFrac = (progress * (0.6 + note.seed)) % 1.2;
      final y = yFrac * size.height;
      note.painter.paint(canvas, Offset(x, y));
      if (index.isEven) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 12, y - 4, 13, 5),
            const Radius.circular(2),
          ),
          Paint()
            ..color = _palette[(index + 1) % _palette.length].withValues(
              alpha: note.alpha,
            ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoteRainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
