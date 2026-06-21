import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../application/auth_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});
  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _ctrl = TextEditingController();

  String _normalize(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) d = d.substring(1);
    return '+84$d';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.authTitle ?? 'Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+84 ', labelText: l10n?.phoneLabel ?? 'Số điện thoại',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('send_otp_btn'),
              onPressed: state.phase == AuthPhase.sending
                  ? null
                  : () => ref.read(authControllerProvider.notifier)
                      .sendOtp(_normalize(_ctrl.text)),
              child: Text(l10n?.sendOtp ?? 'Gửi mã OTP'),
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
