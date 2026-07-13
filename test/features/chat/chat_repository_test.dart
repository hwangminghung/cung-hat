import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import '../../support/supabase_mocks.dart';

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class _MockListFilter extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {}

class _MockListOrdered extends Mock
    implements PostgrestTransformBuilder<PostgrestList> {}

/// Stub chuỗi from(table).select().eq()*.order() trả [rows]; trả filter
/// builder để verify tham số `order`.
PostgrestFilterBuilder<PostgrestList> stubTableSelect(
  MockSupabaseClient client,
  String table,
  PostgrestList rows,
) {
  final qb = _MockQueryBuilder();
  final fb = _MockListFilter();
  final ob = _MockListOrdered();
  when(() => client.from(table)).thenAnswer((_) => qb);
  when(() => qb.select(any())).thenAnswer((_) => fb);
  when(() => fb.eq(any(), any())).thenAnswer((_) => fb);
  when(
    () => fb.order(
      any(),
      ascending: any(named: 'ascending'),
      nullsFirst: any(named: 'nullsFirst'),
      referencedTable: any(named: 'referencedTable'),
    ),
  ).thenAnswer((_) => ob);
  when(
    () => ob.then<dynamic>(any(), onError: any(named: 'onError')),
  ).thenAnswer((invocation) {
    final onValue = invocation.positionalArguments.first as Function;
    return Future<dynamic>.value(rows).then<dynamic>((v) => onValue(v));
  });
  return fb;
}

PostgrestList get _twoDayRows => [
  {
    'id': 'm-cu',
    'thread_id': 't1',
    'sender_id': 'u1',
    'body': 'tin cu',
    'created_at': '2026-07-06T16:09:00Z',
  },
  {
    'id': 'm-moi',
    'thread_id': 't1',
    'sender_id': 'u2',
    'body': 'tin moi',
    'created_at': '2026-07-13T08:01:00Z',
  },
];

void main() {
  test(
    'sendMessage calls send_message RPC with thread + body and returns id',
    () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc('send_message', params: any(named: 'params')),
      ).thenAnswer((_) => rpcOk('m1'));
      final id = await ChatRepository(client).sendMessage('t1', 'hello');
      expect(id, 'm1');
      verify(
        () => client.rpc(
          'send_message',
          params: {'p_thread': 't1', 'p_body': 'hello'},
        ),
      ).called(1);
    },
  );

  test('unmatch calls the unmatch RPC with the match id', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('unmatch', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk(null));
    await expectLater(ChatRepository(client).unmatch('t1'), completes);
    verify(() => client.rpc('unmatch', params: {'p_match': 't1'})).called(1);
  });

  // BUG "chat ngược": SDK Dart .order() MẶC ĐỊNH ascending:false — history
  // phải xin tăng dần tường minh, nếu không tin mới nhất nằm ĐẦU danh sách.
  test('history xin created_at TĂNG dần (cũ trước, mới sau)', () async {
    final client = MockSupabaseClient();
    final fb = stubTableSelect(client, 'messages', _twoDayRows);

    final msgs = await ChatRepository(client).history('t1');

    expect(msgs.map((m) => m.id).toList(), ['m-cu', 'm-moi']);
    verify(
      () => fb.order(
        'created_at',
        ascending: true,
        nullsFirst: any(named: 'nullsFirst'),
        referencedTable: any(named: 'referencedTable'),
      ),
    ).called(1);
  });

  test('keoHistory xin created_at TĂNG dần (cũ trước, mới sau)', () async {
    final client = MockSupabaseClient();
    final fb = stubTableSelect(client, 'messages', _twoDayRows);

    final msgs = await ChatRepository(client).keoHistory('k1');

    expect(msgs.map((m) => m.id).toList(), ['m-cu', 'm-moi']);
    verify(
      () => fb.order(
        'created_at',
        ascending: true,
        nullsFirst: any(named: 'nullsFirst'),
        referencedTable: any(named: 'referencedTable'),
      ),
    ).called(1);
  });

  test('messageFromBroadcast unwraps the frame payload envelope', () {
    final frame = <String, dynamic>{
      'type': 'broadcast',
      'event': 'new_message',
      'payload': {
        'id': 'm1',
        'thread_id': 't1',
        'sender_id': 'u2',
        'body': 'xin chào',
        'created_at': '2026-06-23T10:00:00Z',
      },
    };
    final msg = messageFromBroadcast(frame);
    expect(msg.id, 'm1');
    expect(msg.threadId, 't1');
    expect(msg.senderId, 'u2');
    expect(msg.body, 'xin chào');
  });
}
