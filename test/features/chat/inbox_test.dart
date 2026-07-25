import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('myMatches calls the get_my_matches RPC and maps rows', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_my_matches')).thenAnswer(
      (_) => rpcOk([
        {'match_id': 't1', 'other_id': 'u2', 'other_name': 'Linh', 'unread': 2},
      ]),
    );
    final list = await MatchInbox(client).myMatches();
    expect(list.single.otherName, 'Linh');
    expect(list.single.unread, 2);
  });
}
