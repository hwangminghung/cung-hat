import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/auth/application/auth_controller.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  test('sendOtp moves phase idle -> codeSent', () async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final ctrl = container.read(authControllerProvider.notifier);
    await ctrl.sendOtp('+84900000001');
    expect(container.read(authControllerProvider).phase, AuthPhase.codeSent);
    expect(container.read(authControllerProvider).phone, '+84900000001');
  });
}
