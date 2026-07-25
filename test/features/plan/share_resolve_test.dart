import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('resolveShare calls resolve_share_plan', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('resolve_share_plan', params: any(named: 'params')),
    ).thenAnswer(
      (_) => rpcOk({
        'venue_name': 'Kingdom',
        'address': 'Q1',
        'scheduled_at': '2026-06-21T19:00:00Z',
        'expired': false,
      }),
    );
    final v = await PlanRepository(client).resolveShare('tok');
    expect(v['venue_name'], 'Kingdom');
  });
}
