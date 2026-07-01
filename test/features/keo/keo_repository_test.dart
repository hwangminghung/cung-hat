import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('listOpenKeos maps sanitized board cards', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('list_open_keos', params: any(named: 'params')),
    ).thenAnswer(
      (_) => rpcOk([
        {
          'id': 'k1',
          'title': 'Hat toi T7',
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
      ]),
    );

    final list = await KeoRepository(client).listOpenKeos();

    expect(list.single.title, 'Hat toi T7');
    expect(list.single.slotsFilled, 2);
    expect(list.single.distanceBand, '1-3');
  });

  test('requestJoin calls request_join_keo', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('request_join_keo', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk(null));

    await KeoRepository(client).requestJoin('k1');

    verify(
      () => client.rpc('request_join_keo', params: {'p_keo': 'k1'}),
    ).called(1);
  });

  test('listOpenKeos maps boost fields', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('list_open_keos', params: any(named: 'params')),
    ).thenAnswer(
      (_) => rpcOk([
        {
          'id': 'k1',
          'title': 'Boosted keo',
          'area_label': 'Q1',
          'distance_band': '1-3',
          'time_window_start': '2026-07-01T12:00:00Z',
          'time_window_end': '2026-07-01T15:00:00Z',
          'size_target': 4,
          'slots_filled': 1,
          'genres': ['vpop'],
          'host_name': 'Mai',
          'status': 'open',
          'join_mode': 'open',
          'is_boosted': true,
          'boost_ends_at': '2026-07-02T12:00:00Z',
        },
      ]),
    );

    final list = await KeoRepository(client).listOpenKeos();

    expect(list.single.isBoosted, isTrue);
    expect(list.single.boostEndsAt, '2026-07-02T12:00:00Z');
  });

  test('getKeoDetail calls get_keo_detail', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('get_keo_detail', params: {'p_keo': 'k1'}),
    ).thenAnswer(
      (_) => rpcOk({
        'id': 'k1',
        'title': 'Boosted keo',
        'area_label': 'Q1',
        'distance_band': null,
        'time_window_start': '2026-07-01T12:00:00Z',
        'time_window_end': '2026-07-01T15:00:00Z',
        'size_target': 4,
        'slots_filled': 1,
        'genres': ['vpop'],
        'host_name': 'Mai',
        'status': 'open',
        'join_mode': 'open',
        'is_boosted': true,
        'boost_ends_at': '2026-07-02T12:00:00Z',
      }),
    );

    final keo = await KeoRepository(client).getKeoDetail('k1');

    expect(keo.id, 'k1');
    expect(keo.isBoosted, isTrue);
  });

  test('applyBoost calls apply_keo_boost', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('apply_keo_boost', params: {'p_keo': 'k1'}),
    ).thenAnswer(
      (_) => rpcOk([
        {'boost_id': 'b1', 'ends_at': '2026-07-02T12:00:00Z'},
      ]),
    );

    await KeoRepository(client).applyBoost('k1');

    verify(
      () => client.rpc('apply_keo_boost', params: {'p_keo': 'k1'}),
    ).called(1);
  });
}
