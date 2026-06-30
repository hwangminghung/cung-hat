import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('sendKeoMessage calls send_keo_message RPC', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('send_keo_message', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk('m1'));
    final id = await ChatRepository(client).sendKeoMessage('k1', 'hi nhóm');
    expect(id, 'm1');
    verify(
      () => client.rpc(
        'send_keo_message',
        params: {'p_keo': 'k1', 'p_body': 'hi nhóm'},
      ),
    ).called(1);
  });

  test('deleteMessage calls delete_message RPC', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('delete_message', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk(null));

    await ChatRepository(client).deleteMessage('m1');

    verify(
      () => client.rpc('delete_message', params: {'p_message': 'm1'}),
    ).called(1);
  });
}
