import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/gradient_button.dart';
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

    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.phase != AuthPhase.codeSent &&
          next.phase == AuthPhase.codeSent) {
        context.go('/otp');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const _AuthBackdrop(),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xxxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      AppSpacing.xl -
                      AppSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    const AppLogo(tagline: 'Kết bạn qua những bài hát'),
                    const SizedBox(height: AppSpacing.xxxl),
                    Text(
                      'Đăng nhập bằng số điện thoại',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Nhập số của bạn để nhận mã OTP. Tụi mình chỉ dùng để giữ tài khoản an toàn.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        prefixText: '+84 ',
                        labelText: 'Số điện thoại',
                        hintText: '901 234 567',
                      ),
                      onSubmitted: (_) => _sendOtp(state),
                    ),
                    if (state.phase == AuthPhase.error) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ErrorBanner(message: state.error ?? 'Không gửi được mã'),
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
                          : const Text('Tiếp tục'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Bằng việc tiếp tục, bạn đồng ý dùng Cùng Hát có trách nhiệm và tôn trọng người khác.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendOtp(AuthFlowState state) {
    if (state.phase == AuthPhase.sending) return;
    ref.read(authControllerProvider.notifier).sendOtp(_normalize(_ctrl.text));
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: Stack(
          children: [
            Positioned(
              top: -72,
              right: -48,
              child: _Ribbon(
                color: AppColors.primaryTint.withValues(alpha: 0.90),
                width: 220,
                angle: -0.18,
              ),
            ),
            Positioned(
              top: 112,
              left: -72,
              child: _Ribbon(
                color: AppColors.secondary.withValues(alpha: 0.42),
                width: 190,
                angle: 0.22,
              ),
            ),
            Positioned(
              bottom: 16,
              right: -52,
              child: _Ribbon(
                color: AppColors.tertiaryTint.withValues(alpha: 0.68),
                width: 180,
                angle: -0.26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({
    required this.color,
    required this.width,
    required this.angle,
  });

  final Color color;
  final double width;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
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
