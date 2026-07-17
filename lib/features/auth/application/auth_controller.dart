import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;

import '../../../core/analytics/analytics_service.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_providers.dart';

enum AuthPhase { idle, sending, codeSent, verifying, verified, error }

/// Phân loại lỗi auth cho UI (UI review vòng cuối 2026-07-17): state KHÔNG
/// bao giờ giữ `e.toString()` — chuỗi kỹ thuật (AuthApiException, URL
/// Twilio, status code…) chỉ được debugPrint, UI map kind → message VI.
enum AuthErrorKind { sendFailed, otpInvalid, network, unknown }

/// Message thân thiện đã localization cho từng [AuthErrorKind] — fallback VI
/// theo idiom `l10n?.key ?? 'vi'` của repo.
String authErrorMessage(AuthErrorKind kind, AppLocalizations? l10n) =>
    switch (kind) {
      AuthErrorKind.sendFailed =>
        l10n?.authErrorSendFailed ??
            'Không thể gửi mã OTP. Vui lòng kiểm tra số điện thoại và thử lại.',
      AuthErrorKind.otpInvalid =>
        l10n?.authErrorOtpInvalid ??
            'Mã OTP không đúng hoặc đã hết hạn. Vui lòng thử lại.',
      AuthErrorKind.network =>
        l10n?.authErrorNetwork ??
            'Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.',
      AuthErrorKind.unknown =>
        l10n?.authErrorGeneric ?? 'Đã có lỗi xảy ra. Vui lòng thử lại.',
    };

class AuthFlowState {
  const AuthFlowState({this.phase = AuthPhase.idle, this.phone, this.error});
  final AuthPhase phase;
  final String? phone;

  /// Kind đã phân loại — không phải chuỗi exception.
  final AuthErrorKind? error;

  AuthFlowState copyWith({
    AuthPhase? phase,
    String? phone,
    AuthErrorKind? error,
  }) => AuthFlowState(
    phase: phase ?? this.phase,
    phone: phone ?? this.phone,
    error: error,
  );
}

class AuthController extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState();

  /// Chi tiết kỹ thuật CHỈ vào log debug; UI nhận kind an toàn.
  AuthErrorKind _classify(Object e, {required bool verifying}) {
    debugPrint('auth ${verifying ? 'verify' : 'send'} failed: $e');
    if (e is AuthRetryableFetchException || e is SocketException) {
      return AuthErrorKind.network;
    }
    if (e is AuthException) {
      return verifying ? AuthErrorKind.otpInvalid : AuthErrorKind.sendFailed;
    }
    return AuthErrorKind.unknown;
  }

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(phase: AuthPhase.sending, phone: phone);
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      state = state.copyWith(phase: AuthPhase.codeSent, phone: phone);
    } catch (e) {
      state = state.copyWith(
        phase: AuthPhase.error,
        error: _classify(e, verifying: false),
      );
    }
  }

  Future<void> verifyOtp(String token) async {
    final phone = state.phone;
    if (phone == null) return;
    state = state.copyWith(phase: AuthPhase.verifying, phone: phone);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(phone, token);
      // P0-3: fire-and-forget — telemetry không được chặn/making fail flow auth.
      unawaited(ref.read(analyticsProvider).logLogin());
      state = state.copyWith(phase: AuthPhase.verified, phone: phone);
    } catch (e) {
      state = state.copyWith(
        phase: AuthPhase.error,
        error: _classify(e, verifying: true),
      );
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthFlowState>(
  AuthController.new,
);
