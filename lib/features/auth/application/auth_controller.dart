import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_service.dart';
import 'auth_providers.dart';

enum AuthPhase { idle, sending, codeSent, verifying, verified, error }

class AuthFlowState {
  const AuthFlowState({this.phase = AuthPhase.idle, this.phone, this.error});
  final AuthPhase phase;
  final String? phone;
  final String? error;

  AuthFlowState copyWith({AuthPhase? phase, String? phone, String? error}) =>
      AuthFlowState(
        phase: phase ?? this.phase,
        phone: phone ?? this.phone,
        error: error,
      );
}

class AuthController extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState();

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(phase: AuthPhase.sending, phone: phone);
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      state = state.copyWith(phase: AuthPhase.codeSent, phone: phone);
    } catch (e) {
      state = state.copyWith(phase: AuthPhase.error, error: e.toString());
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
      state = state.copyWith(phase: AuthPhase.error, error: e.toString());
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthFlowState>(AuthController.new);
