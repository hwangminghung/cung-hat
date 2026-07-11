import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/features/auth/application/auth_controller.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/auth/presentation/otp_screen.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  testWidgets('renders the approved outlined OTP ticket hierarchy', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
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

    expect(find.byKey(const Key('otp_brand_header')), findsOneWidget);
    expect(find.text('Cùng Hát'), findsOneWidget);
    expect(find.text('Nhập mã OTP'), findsOneWidget);

    final ticket = tester.widget<Container>(
      find.byKey(const Key('otp_ticket_hero')),
    );
    final decoration = ticket.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, AppColors.ink);
    expect(border.top.width, 2);
    expect(decoration.boxShadow?.single.offset, const Offset(3, 3));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resend countdown starts at 60 and ticks once per second', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
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

    expect(find.text('Gửi lại mã sau 60s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gửi lại mã sau 59s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gửi lại mã sau 58s'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resend action reuses the phone and resets the countdown', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');
    clearInteractions(repo);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OtpScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 60));
    expect(find.text('Gửi lại mã'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resend_otp_btn')));
    await tester.pump();

    verify(() => repo.sendOtp('+84900000001')).called(1);
    expect(find.text('Gửi lại mã sau 60s'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resend countdown timer is cancelled when screen is disposed', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
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

    expect(find.text('Gửi lại mã sau 60s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 61));

    expect(tester.takeException(), isNull);
  });

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

  testWidgets('verify button retries after auto-submit fails', (tester) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    var attempts = 0;
    when(() => repo.verifyOtp(any(), any())).thenAnswer((_) async {
      attempts += 1;
      if (attempts == 1) throw Exception('bad otp');
      return AuthResponse(session: null, user: null);
    });
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
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(container.read(authControllerProvider).phase, AuthPhase.error);

    await tester.tap(find.byKey(const Key('verify_otp_btn')));
    await tester.pump();

    expect(attempts, 2);
  });
}
