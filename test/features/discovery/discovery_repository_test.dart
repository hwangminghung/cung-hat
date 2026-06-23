import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('getCandidates maps the sanitized RPC rows', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_discovery_candidates', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk([
              {'id': 'u2', 'display_name': 'Linh', 'age': 24, 'distance_band': '1-3',
               'shared_genres': ['vpop'], 'shared_baitu': ['s2'], 'verified': true, 'active_today': true},
            ]));
    final list = await DiscoveryRepository(client).getCandidates();
    expect(list.single.displayName, 'Linh');
    expect(list.single.distanceBand, '1-3');
    expect(list.single.sharedGenres, ['vpop']);
  });

  test('recordSwipe returns matched flag', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('record_swipe', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(true));
    final matched = await DiscoveryRepository(client).recordSwipe('u2', 'like');
    expect(matched, isTrue);
    verify(() => client.rpc('record_swipe',
        params: {'p_target': 'u2', 'p_direction': 'like'})).called(1);
  });

  test('updateMyLocation sends p_lat/p_lng/p_area (area defaults null)', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('update_my_location', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(null));
    await DiscoveryRepository(client).updateMyLocation(10.77, 106.70);
    verify(() => client.rpc('update_my_location',
        params: {'p_lat': 10.77, 'p_lng': 106.70, 'p_area': null})).called(1);
  });
}
