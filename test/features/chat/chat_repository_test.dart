import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('sendMessage calls send_message RPC with thread + body and returns id', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('send_message', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk('m1'));
    final id = await ChatRepository(client).sendMessage('t1', 'hello');
    expect(id, 'm1');
    verify(() => client.rpc('send_message',
        params: {'p_thread': 't1', 'p_body': 'hello'})).called(1);
  });
}
