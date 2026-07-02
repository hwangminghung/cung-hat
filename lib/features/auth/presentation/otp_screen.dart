import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/otp_input.dart';
import '../application/auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();

  /// Prevents auto-submit and the manual button from sending the same code
  /// twice, which can make Supabase report a misleading expired OTP.
  bool _submitted = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(String code) {
    if (_submitted) return;
    _submitted = true;
    ref.read(authControllerProvider.notifier).verifyOtp(code);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (prev, next) {
      if (next.phase == AuthPhase.error) {
        _submitted = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập mã OTP'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.sms_rounded,
                        color: AppColors.primaryDark,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Kiểm tra tin nhắn',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Mã đã gửi tới ${state.phone ?? 'số điện thoại của bạn'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    OtpInput(
                      onChanged: (value) {
                        _ctrl.text = value;
                        _submitted = false;
                      },
                      onCompleted: _submit,
                    ),
                  ],
                ),
              ),
              if (state.phase == AuthPhase.error) ...[
                const SizedBox(height: AppSpacing.md),
                _ErrorBanner(message: state.error ?? 'Mã OTP chưa đúng'),
              ],
              const SizedBox(height: AppSpacing.xl),
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
                    : const Text('Xác nhận'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Không nhận được mã? Quay lại để kiểm tra số điện thoại.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
