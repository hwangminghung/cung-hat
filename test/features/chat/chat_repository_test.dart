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

/// Stub chuỗi from(table).select().eq()*.order().limit() trả [rows]; trả
/// (filter, ordered) để verify tham số `order` và `limit`.
({
  PostgrestFilterBuilder<PostgrestList> fb,
  PostgrestTransformBuilder<PostgrestList> ob,
})
stubTableSelect(MockSupabaseClient client, String table, PostgrestList rows) {
  final qb = _MockQueryBuilder();
  final fb = _MockListFilter();
  final ob = _MockListOrdered();
  final lb = _MockListOrdered();
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
    () => ob.limit(any(), referencedTable: any(named: 'referencedTable')),
  ).thenAnswer((_) => lb);
  when(
    () => lb.then<dynamic>(any(), onError: any(named: 'onError')),
  ).thenAnswer((invocation) {
    final onValue = invocation.positionalArguments.first as Function;
    return Future<dynamic>.value(rows).then<dynamic>((v) => onValue(v));
  });
  return (fb: fb, ob: ob);
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

  // BUG audit H2: PostgREST max_rows=1000 cắt ÂM THẦM; order tăng dần làm
  // thread >1000 tin MẤT SẠCH tin mới nhất. Hành vi đúng: lấy trang MỚI nhất
  // (desc + limit) rồi đảo lại cho UI cũ→mới.
  test('history lấy trang MỚI nhất (desc+limit) rồi đảo về cũ→mới', () async {
    final client = MockSupabaseClient();
    // Server trả DESC: tin mới trước.
    final stubs = stubTableSelect(client, 'messages', [
      _twoDayRows[1],
      _twoDayRows[0],
    ]);

    final msgs = await ChatRepository(client).history('t1');

    expect(msgs.map((m) => m.id).toList(), ['m-cu', 'm-moi']);
    verify(
      () => stubs.fb.order(
        'created_at',
        ascending: false,
        nullsFirst: any(named: 'nullsFirst'),
        referencedTable: any(named: 'referencedTable'),
      ),
    ).called(1);
    verify(
      () => stubs.ob.limit(
        ChatRepository.historyPageSize,
        referencedTable: any(named: 'referencedTable'),
      ),
    ).called(1);
  });

  test('keoHistory lấy trang MỚI nhất (desc+limit) rồi đảo về cũ→mới',
      () async {
    final client = MockSupabaseClient();
    final stubs = stubTableSelect(client, 'messages', [
      _twoDayRows[1],
      _twoDayRows[0],
    ]);

    final msgs = await ChatRepository(client).keoHistory('k1');

    expect(msgs.map((m) => m.id).toList(), ['m-cu', 'm-moi']);
    verify(
      () => stubs.fb.order(
        'created_at',
        ascending: false,
        nullsFirst: any(named: 'nullsFirst'),
        referencedTable: any(named: 'referencedTable'),
      ),
    ).called(1);
    verify(
      () => stubs.ob.limit(
        ChatRepository.historyPageSize,
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
