import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthApiException, AuthResponse;
import 'package:cung_hat/core/analytics/analytics_service.dart';
import 'package:cung_hat/features/auth/application/auth_controller.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';

import '../../support/analytics_fakes.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  test('sendOtp moves phase idle -> codeSent', () async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(authControllerProvider.notifier);
    await ctrl.sendOtp('+84900000001');
    expect(container.read(authControllerProvider).phase, AuthPhase.codeSent);
    expect(container.read(authControllerProvider).phone, '+84900000001');
  });

  test('verifyOtp thành công → log event login (P0-3)', () async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    when(
      () => repo.verifyOtp(any(), any()),
    ).thenAnswer((_) async => AuthResponse());
    final analytics = RecordingAnalytics();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(authControllerProvider.notifier);
    await ctrl.sendOtp('+84900000001');
    await ctrl.verifyOtp('123456');
    expect(analytics.events, ['login']);
  });

  test('verifyOtp lỗi → KHÔNG log login (P0-3)', () async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    when(
      () => repo.verifyOtp(any(), any()),
    ).thenThrow(Exception('otp_expired'));
    final analytics = RecordingAnalytics();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(authControllerProvider.notifier);
    await ctrl.sendOtp('+84900000001');
    await ctrl.verifyOtp('000000');
    expect(container.read(authControllerProvider).phase, AuthPhase.error);
    expect(analytics.events, isEmpty);
  });

  // UI review vòng cuối: state KHÔNG bao giờ giữ e.toString() — chỉ giữ
  // AuthErrorKind đã phân loại để UI map sang message VI thân thiện.
  test(
    'sendOtp ném AuthApiException → error = sendFailed (không raw)',
    () async {
      final repo = _MockRepo();
      when(() => repo.sendOtp(any())).thenThrow(
        AuthApiException(
          'Error sending confirmation OTP to provider: see '
          'https://www.twilio.com/docs/errors/60203',
          statusCode: '422',
          code: 'sms_send_failed',
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container
          .read(authControllerProvider.notifier)
          .sendOtp('+84900000001');
      final state = container.read(authControllerProvider);
      expect(state.phase, AuthPhase.error);
      expect(state.error, AuthErrorKind.sendFailed);
    },
  );

  test('verifyOtp ném AuthApiException → error = otpInvalid', () async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    when(() => repo.verifyOtp(any(), any())).thenThrow(
      AuthApiException(
        'Token has expired or is invalid',
        statusCode: '403',
        code: 'otp_expired',
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(authControllerProvider.notifier);
    await ctrl.sendOtp('+84900000001');
    await ctrl.verifyOtp('000000');
    expect(
      container.read(authControllerProvider).error,
      AuthErrorKind.otpInvalid,
    );
  });

  test('lỗi mạng (SocketException) → error = network', () async {
    final repo = _MockRepo();
    when(
      () => repo.sendOtp(any()),
    ).thenThrow(const SocketException('Failed host lookup: supabase.co'));
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');
    expect(container.read(authControllerProvider).error, AuthErrorKind.network);
  });
}
