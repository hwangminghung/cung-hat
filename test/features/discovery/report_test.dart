import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('reportUser calls report_user RPC', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('report_user', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(null));
    await DiscoveryRepository(client).reportUser('u2', 'spam');
    verify(() => client.rpc('report_user',
        params: {'p_target': 'u2', 'p_reason': 'spam'})).called(1);
  });

  test('blockUser calls block_user RPC', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('block_user', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(null));
    await DiscoveryRepository(client).blockUser('u2');
    verify(() => client.rpc('block_user', params: {'p_blocked': 'u2'})).called(1);
  });
}
