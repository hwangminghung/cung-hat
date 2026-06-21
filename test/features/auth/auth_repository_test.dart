import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockAuth extends Mock implements GoTrueClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(OtpType.sms);
  });

  late _MockClient client;
  late _MockAuth auth;
  setUp(() {
    client = _MockClient();
    auth = _MockAuth();
    when(() => client.auth).thenReturn(auth);
  });

  test('sendOtp calls signInWithOtp with the phone', () async {
    when(() => auth.signInWithOtp(phone: any(named: 'phone')))
        .thenAnswer((_) async {});
    await AuthRepository(client).sendOtp('+84900000001');
    verify(() => auth.signInWithOtp(phone: '+84900000001')).called(1);
  });

  test('verifyOtp calls verifyOTP with sms type', () async {
    when(() => auth.verifyOTP(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        )).thenAnswer((_) async => AuthResponse(session: null, user: null));
    await AuthRepository(client).verifyOtp('+84900000001', '123456');
    verify(() => auth.verifyOTP(
        phone: '+84900000001', token: '123456', type: OtpType.sms)).called(1);
  });
}
