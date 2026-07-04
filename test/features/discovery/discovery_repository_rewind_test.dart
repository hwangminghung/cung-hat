import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('undoLastSwipe gọi RPC và trả bool', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('undo_last_swipe')).thenAnswer((_) => rpcOk(true));
    final repo = DiscoveryRepository(client);
    expect(await repo.undoLastSwipe(), isTrue);
  });

  test('getMatchIdWith trả uuid hoặc null', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_match_id_with', params: {'p_other': 'u1'}))
        .thenAnswer((_) => rpcOk('m-uuid'));
    final repo = DiscoveryRepository(client);
    expect(await repo.getMatchIdWith('u1'), 'm-uuid');
  });

  test('activateBoost parse chuỗi ISO thành DateTime hết hạn', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('activate_boost'))
        .thenAnswer((_) => rpcOk('2026-07-04T10:30:00.000Z'));
    final repo = DiscoveryRepository(client);
    expect(await repo.activateBoost(),
        DateTime.parse('2026-07-04T10:30:00.000Z'));
  });
}
