import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class MatchCelebration extends StatelessWidget {
  const MatchCelebration({
    super.key,
    required this.otherName,
    required this.sharedBaitu,
    required this.onChat,
  });

  final String otherName;
  final List<String> sharedBaitu;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.onPrimary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.mic_external_on_rounded,
            color: AppColors.onPrimary,
            size: 44,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Chung gu!',
          style: AppTypography.display(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Bạn và $otherName cùng ${sharedBaitu.length} bài tủ',
          style: const TextStyle(color: AppColors.onPrimary, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.onPrimary,
            foregroundColor: AppColors.primaryDark,
          ),
          onPressed: onChat,
          icon: const Icon(Icons.chat_bubble_rounded),
          label: const Text('Rủ đi hát'),
        ),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: reduceMotion
                  ? content
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: AppMotion.slow,
                      curve: AppMotion.springCurve,
                      builder: (context, t, child) => Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.85 + 0.15 * t,
                          child: child,
                        ),
                      ),
                      child: content,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
