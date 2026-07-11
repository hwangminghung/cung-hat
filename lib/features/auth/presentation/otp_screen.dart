import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/otp_input.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../application/auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();

  static const _resendStartSeconds = 60;
  Timer? _resendTimer;
  int _secondsRemaining = _resendStartSeconds;

  /// Prevents auto-submit and the manual button from sending the same code
  /// twice, which can make Supabase report a misleading expired OTP.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _startResendCountdown(notify: false);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startResendCountdown({bool notify = true}) {
    _resendTimer?.cancel();
    if (notify && mounted) {
      setState(() => _secondsRemaining = _resendStartSeconds);
    } else {
      _secondsRemaining = _resendStartSeconds;
    }
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  void _resendOtp(String? phone) {
    if (phone == null) return;
    _startResendCountdown();
    ref.read(authControllerProvider.notifier).sendOtp(phone);
  }

  void _submit(String code) {
    if (_submitted) return;
    _submitted = true;
    ref.read(authControllerProvider.notifier).verifyOtp(code);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final phone =
        state.phone ?? l10n?.authPhoneFallback ?? 'số điện thoại của bạn';

    ref.listen(authControllerProvider, (prev, next) {
      if (next.phase == AuthPhase.error) {
        _submitted = false;
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
                  _BrandHeader(brand: l10n?.appTitle ?? 'Cùng Hát'),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    l10n?.otpTitle ?? 'Nhập mã OTP',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Align(
                    alignment: Alignment.center,
                    child: _TicketHero(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n?.authCheckMessages ?? 'Kiểm tra tin nhắn',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n?.authOtpSentTo(phone) ?? 'Mã đã gửi tới $phone',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  OtpInput(
                    onChanged: (value) {
                      _ctrl.text = value;
                      _submitted = false;
                    },
                    onCompleted: _submit,
                  ),
                  if (state.phase == AuthPhase.error) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ErrorBanner(
                      message:
                          state.error ??
                          l10n?.authOtpError ??
                          'Mã OTP chưa đúng',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  GradientButton(
                    key: const Key('verify_otp_btn'),
                    icon: Icons.check_rounded,
                    onPressed: state.phase == AuthPhase.verifying
                        ? null
                        : () => _submit(_ctrl.text),
                    child: state.phase == AuthPhase.verifying
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(l10n?.verify ?? 'Xác nhận'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_secondsRemaining > 0)
                    Text(
                      l10n?.authResendCountdown(_secondsRemaining) ??
                          'Gửi lại mã sau ${_secondsRemaining}s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Center(
                      child: TextButton(
                        key: const Key('resend_otp_btn'),
                        onPressed:
                            state.phone == null ||
                                state.phase == AuthPhase.sending
                            ? null
                            : () => _resendOtp(state.phone),
                        child: Text(l10n?.authResend ?? 'Gửi lại mã'),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: const Icon(
                          Icons.question_mark_rounded,
                          color: AppColors.ink,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          l10n?.authOtpHelp ??
                              'Không nhận được mã? Quay lại để kiểm tra số điện thoại.',
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
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('otp_brand_header'),
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.ink, width: 2),
            boxShadow: const [AppShadows.hard],
          ),
          child: const BackButton(color: AppColors.ink),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.secondaryDark,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                brand,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(
                width: 38,
                child: WaveDivider(
                  height: AppSpacing.lg,
                  color: AppColors.teal,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _TicketHero extends StatelessWidget {
  const _TicketHero();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.025,
      child: Container(
        key: const Key('otp_ticket_hero'),
        width: 286,
        height: 116,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: const [AppShadows.hard],
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 28,
              right: 52,
              bottom: 6,
              child: WaveDivider(
                height: 24,
                color: AppColors.teal,
                strokeWidth: 2,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 66,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MessageDot(),
                      SizedBox(width: AppSpacing.xs),
                      _MessageDot(),
                      SizedBox(width: AppSpacing.xs),
                      _MessageDot(),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppSpacing.xs),
                      _TicketLine(width: 66),
                      SizedBox(height: AppSpacing.sm),
                      _TicketLine(width: 88),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const _Perforation(),
                const SizedBox(width: AppSpacing.md),
                const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.ink,
                  size: 34,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageDot extends StatelessWidget {
  const _MessageDot();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
      child: SizedBox.square(dimension: 7),
    );
  }
}

class _TicketLine extends StatelessWidget {
  const _TicketLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < 6; i++)
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: 4),
          ),
      ],
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
