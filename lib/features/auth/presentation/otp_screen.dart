import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập mã OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mã đã gửi tới ${state.phone ?? ''}'),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mã 6 số'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('verify_otp_btn'),
              onPressed: state.phase == AuthPhase.verifying
                  ? null
                  : () => ref.read(authControllerProvider.notifier).verifyOtp(_ctrl.text),
              child: const Text('Xác nhận'),
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
