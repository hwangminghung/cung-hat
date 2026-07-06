import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/auth/application/auth_controller.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/auth/presentation/otp_screen.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  testWidgets('entering code and tapping verify calls verifyOtp', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    when(
      () => repo.verifyOtp(any(), any()),
    ).thenAnswer((_) async => AuthResponse(session: null, user: null));
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OtpScreen()),
      ),
    );
    // The 6-box OtpInput auto-submits on completion; tapping the verify button
    // afterwards must NOT fire a second verify for the same code (guarded by
    // _submitted) — verifyOtp runs exactly once with the entered code.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.byKey(const Key('verify_otp_btn')));
    await tester.pump();
    verify(() => repo.verifyOtp('+84900000001', '123456')).called(1);
  });

  testWidgets('successful verification leaves the OTP screen', (tester) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    when(
      () => repo.verifyOtp(any(), any()),
    ).thenAnswer((_) async => AuthResponse(session: null, user: null));
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');

    final router = GoRouter(
      initialLocation: '/otp',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home stub')),
        GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    expect(find.text('home stub'), findsOneWidget);
  });
}
