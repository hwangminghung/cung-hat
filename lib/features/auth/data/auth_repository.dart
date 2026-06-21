import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Future<void> sendOtp(String phone) => _client.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyOtp(String phone, String token) =>
      _client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);

  Future<void> signOut() => _client.auth.signOut();

  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
