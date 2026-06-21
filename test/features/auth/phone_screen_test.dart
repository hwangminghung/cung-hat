import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/auth/presentation/phone_screen.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  testWidgets('entering a number and tapping send calls sendOtp', (tester) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: PhoneScreen()),
    ));
    await tester.enterText(find.byType(TextField), '900000001');
    await tester.tap(find.byKey(const Key('send_otp_btn')));
    await tester.pump();
    verify(() => repo.sendOtp('+84900000001')).called(1);
  });
}
