import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../application/auth_controller.dart';
import '../../../shared/widgets/otp_input.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();

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
            Text('Mã đã gửi tới ${state.phone ?? ''}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OtpInput(
              onChanged: (v) => _ctrl.text = v,
              onCompleted: (v) {
                _ctrl.text = v;
                ref.read(authControllerProvider.notifier).verifyOtp(v);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('verify_otp_btn'),
              onPressed: state.phase == AuthPhase.verifying
                  ? null
                  : () => ref.read(authControllerProvider.notifier).verifyOtp(_ctrl.text),
              child: Text(l10n?.verify ?? 'Xác nhận'),
            ),
            if (state.phase == AuthPhase.error)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(state.error ?? 'Lỗi', style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
