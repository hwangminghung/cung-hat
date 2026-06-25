import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/push/push_service.dart';
import '../support/supabase_mocks.dart';

void main() {
  test('registerToken calls register_device_token RPC', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('register_device_token', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(null));
    await PushService(client).registerToken('tok', 'android');
    verify(() => client.rpc('register_device_token',
        params: {'p_token': 'tok', 'p_platform': 'android'})).called(1);
  });
}
