import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('listOpenKeos maps sanitized board cards', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('list_open_keos', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk([
              {
                'id': 'k1',
                'title': 'Hát tối T7',
                'area_label': 'Q1',
                'distance_band': '1-3',
                'time_window_start': '2026-06-21T19:00:00Z',
                'time_window_end': '2026-06-21T22:00:00Z',
                'size_target': 4,
                'slots_filled': 2,
                'genres': ['vpop'],
                'host_name': 'Mai',
                'status': 'open',
              },
            ]));
    final list = await KeoRepository(client).listOpenKeos();
    expect(list.single.title, 'Hát tối T7');
    expect(list.single.slotsFilled, 2);
    expect(list.single.distanceBand, '1-3');
  });

  test('requestJoin calls request_join_keo', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('request_join_keo', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(null));
    await KeoRepository(client).requestJoin('k1');
    verify(() => client.rpc('request_join_keo', params: {'p_keo': 'k1'}))
        .called(1);
  });
}
