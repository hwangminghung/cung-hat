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

  test('messageFromBroadcast unwraps the frame payload envelope', () {
    final frame = <String, dynamic>{
      'type': 'broadcast',
      'event': 'new_message',
      'payload': {
        'id': 'm1', 'thread_id': 't1', 'sender_id': 'u2',
        'body': 'xin chào', 'created_at': '2026-06-23T10:00:00Z',
      },
    };
    final msg = messageFromBroadcast(frame);
    expect(msg.id, 'm1');
    expect(msg.threadId, 't1');
    expect(msg.senderId, 'u2');
    expect(msg.body, 'xin chào');
  });
}
