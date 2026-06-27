import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';
import '../../../shared/widgets/otp_input.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();

  /// True once the current code has been submitted, so the auto-submit on
  /// completion and the manual "Xác nhận" button can never both fire a verify
  /// for the same code (a double RPC can surface a spurious "OTP expired").
  /// Reset whenever the code changes so a corrected code can be retried.
  bool _submitted = false;

  void _submit(String code) {
    if (_submitted) return;
    _submitted = true;
    ref.read(authControllerProvider.notifier).verifyOtp(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.otpTitle ?? 'Nhập mã OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mã đã gửi tới ${state.phone ?? ''}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OtpInput(
              onChanged: (v) {
                _ctrl.text = v;
                _submitted = false; // code changed → allow a fresh submit
              },
              onCompleted: _submit, // primary path: auto-submit on completion
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('verify_otp_btn'),
                // Manual fallback. The _submitted guard prevents a duplicate
                // verify when the user both completes the code and taps this.
                onPressed: state.phase == AuthPhase.verifying
                    ? null
                    : () => _submit(_ctrl.text),
                child: Text(l10n?.verify ?? 'Xác nhận'),
              ),
            ),
            if (state.phase == AuthPhase.error)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  state.error ?? 'Lỗi',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
