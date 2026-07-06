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
  testWidgets(
    'entering code and tapping verify calls verifyOtp then leaves otp',
    (tester) async {
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
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home route')),
          ),
          GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.byKey(const Key('verify_otp_btn')));
      await tester.pumpAndSettle();
      verify(() => repo.verifyOtp('+84900000001', '123456')).called(1);
      expect(find.text('home route'), findsOneWidget);
    },
  );
}
