import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/admin/data/moderation_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('listReports calls admin_list_reports', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('admin_list_reports', params: any(named: 'params')),
    ).thenAnswer(
      (_) => rpcOk([
        {
          'id': 'r1',
          'target_type': 'profile',
          'target_id': 'u2',
          'reason': 'spam',
          'status': 'open',
        },
      ]),
    );
    final list = await ModerationRepository(client).listReports();
    expect(list.single.id, 'r1');
  });

  test('action calls admin_action_report', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('admin_action_report', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk(null));
    await ModerationRepository(client).action('r1', 'remove', reason: 'abuse');
    verify(
      () => client.rpc(
        'admin_action_report',
        params: {'p_report': 'r1', 'p_action': 'remove', 'p_reason': 'abuse'},
      ),
    ).called(1);
  });
}
