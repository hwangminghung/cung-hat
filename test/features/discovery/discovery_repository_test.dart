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

  group('getMatchProfile', () {
    test('maps a valid composite row into a Candidate', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('get_match_profile', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk({
                'id': 'u2',
                'display_name': 'Linh',
                'age': 24,
                'distance_band': '1-3',
                'shared_genres': ['vpop'],
                'shared_baitu': ['song-chung'],
                'verified': true,
                'active_today': true,
                'bio': 'Hat ballad',
                'prompts': [
                  {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
                ],
              }));
      final result =
          await DiscoveryRepository(client).getMatchProfile('m1');
      expect(result, isNotNull);
      expect(result!.id, 'u2');
      expect(result.displayName, 'Linh');
      expect(result.sharedBaitu, ['song-chung']);
      expect(result.prompts.single['prompt_id'], 'p1');
      verify(() => client.rpc('get_match_profile', params: {'p_match': 'm1'}))
          .called(1);
    });

    test('returns null when the RPC result is null (defensive)', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('get_match_profile', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk(null));
      final result = await DiscoveryRepository(client).getMatchProfile('m1');
      expect(result, isNull);
    });

    test('returns null when the composite row is empty (other user soft-deleted)',
        () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('get_match_profile', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk({
                'id': null,
                'display_name': null,
                'age': null,
                'distance_band': null,
                'shared_genres': null,
                'shared_baitu': null,
                'verified': null,
                'active_today': null,
                'bio': null,
                'prompts': null,
              }));
      final result = await DiscoveryRepository(client).getMatchProfile('m1');
      expect(result, isNull);
    });

    test('unwraps a List-shaped result (defensive against setof-style response)',
        () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('get_match_profile', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk([
                {
                  'id': 'u2',
                  'display_name': 'Linh',
                  'age': 24,
                  'distance_band': '1-3',
                  'shared_genres': ['vpop'],
                  'shared_baitu': ['song-chung'],
                  'verified': true,
                  'active_today': true,
                  'bio': 'Hat ballad',
                  'prompts': <Map<String, dynamic>>[],
                },
              ]));
      final result = await DiscoveryRepository(client).getMatchProfile('m1');
      expect(result, isNotNull);
      expect(result!.id, 'u2');
    });
  });
}
