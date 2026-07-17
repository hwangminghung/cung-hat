import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../application/auth_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _ctrl = TextEditingController();

  String _normalize(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+84$digits';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.phase != AuthPhase.codeSent &&
          next.phase == AuthPhase.codeSent) {
        context.go('/otp');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppLogo(
                    tagline: l10n?.authTagline ?? 'Kết bạn qua những bài hát',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // UI review: hạ minh họa để khối nhập liệu + nút chính
                  // không bị đẩy quá thấp khi bàn phím mở trên màn phổ biến.
                  const _MusicBoxHero(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n?.authPhoneTitle ?? 'Đăng nhập bằng số điện thoại',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n?.authPhoneBody ??
                        'Nhập số của bạn để nhận mã OTP. Tụi mình chỉ dùng để giữ tài khoản an toàn.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    key: const Key('phone_input_frame'),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusInput,
                      ),
                      border: Border.all(color: AppColors.ink, width: 2),
                      boxShadow: const [AppShadows.hard],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.lg),
                          child: Text(
                            '+84',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.ink,
                          size: 20,
                        ),
                        Container(
                          width: 2,
                          height: 38,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          color: AppColors.ink,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: l10n?.phoneLabel ?? 'Số điện thoại',
                              hintText: l10n?.authPhoneHint ?? '901 234 567',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.fromLTRB(
                                0,
                                AppSpacing.sm,
                                AppSpacing.lg,
                                AppSpacing.sm,
                              ),
                            ),
                            onSubmitted: (_) => _sendOtp(state),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.phase == AuthPhase.error) ...[
                    const SizedBox(height: AppSpacing.md),
                    // Vòng cuối UI review: chỉ render message đã map từ
                    // AuthErrorKind — không bao giờ là exception.toString().
                    _ErrorBanner(
                      message: authErrorMessage(
                        state.error ?? AuthErrorKind.sendFailed,
                        l10n,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  GradientButton(
                    key: const Key('send_otp_btn'),
                    icon: Icons.arrow_forward_rounded,
                    onPressed: state.phase == AuthPhase.sending
                        ? null
                        : () => _sendOtp(state),
                    child: state.phase == AuthPhase.sending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(l10n?.onbContinue ?? 'Tiếp tục'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.ink,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          l10n?.authResponsibility ??
                              'Bằng việc tiếp tục, bạn đồng ý dùng Cùng Hát có trách nhiệm và tôn trọng người khác.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendOtp(AuthFlowState state) {
    if (state.phase == AuthPhase.sending) return;
    ref.read(authControllerProvider.notifier).sendOtp(_normalize(_ctrl.text));
  }
}

class _MusicBoxHero extends StatelessWidget {
  const _MusicBoxHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 16,
            top: 22,
            child: Transform.rotate(
              angle: -0.18,
              child: const Icon(
                Icons.music_note_rounded,
                color: AppColors.primary,
                size: 31,
              ),
            ),
          ),
          const Positioned(
            right: 18,
            top: 4,
            child: Icon(
              Icons.library_music_rounded,
              color: AppColors.teal,
              size: 34,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              key: const Key('login_music_box_hero'),
              width: 244,
              height: 136,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [AppShadows.hard],
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.queue_music_rounded,
                        color: AppColors.ink,
                        size: 22,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: WaveDivider(
                          height: AppSpacing.lg,
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.headphones_rounded,
                        color: AppColors.ink,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.ink, width: 2),
                      ),
                      child: const Stack(
                        children: [
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: WaveDivider(
                              height: 24,
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _Singer(accent: AppColors.secondary),
                                SizedBox(width: AppSpacing.md),
                                _Singer(accent: AppColors.teal, raised: true),
                                SizedBox(width: AppSpacing.md),
                                _Singer(accent: AppColors.primaryTint),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            right: 38,
            bottom: 12,
            child: Icon(
              Icons.music_note_rounded,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          const Positioned(
            left: 36,
            bottom: 4,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.secondaryDark,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}

class _Singer extends StatelessWidget {
  const _Singer({required this.accent, this.raised = false});

  final Color accent;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: raised ? 10 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.ink,
              size: 21,
            ),
          ),
          Transform.rotate(
            angle: -0.25,
            child: const Icon(
              Icons.mic_rounded,
              color: AppColors.ink,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        border: Border.all(color: AppColors.error, width: 2),
        boxShadow: const [AppShadows.hard],
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
