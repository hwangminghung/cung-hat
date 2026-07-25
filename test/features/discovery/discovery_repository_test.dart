import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import '../../support/supabase_mocks.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

class _MockStorage extends Mock implements SupabaseStorageClient {}

void main() {
  test('getCandidates maps the sanitized RPC rows', () async {
    final client = MockSupabaseClient();
    when(
      () =>
          client.rpc('get_discovery_candidates', params: any(named: 'params')),
    ).thenAnswer(
      (_) => rpcOk([
        {
          'id': 'u2',
          'display_name': 'Linh',
          'age': 24,
          'distance_band': '1-3',
          'shared_genres': ['vpop'],
          'shared_baitu': ['s2'],
          'verified': true,
          'active_today': true,
        },
      ]),
    );
    final list = await DiscoveryRepository(client).getCandidates();
    expect(list.single.displayName, 'Linh');
    expect(list.single.distanceBand, '1-3');
    expect(list.single.sharedGenres, ['vpop']);
  });

  test('recordSwipe returns matched flag', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('record_swipe', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk(true));
    final matched = await DiscoveryRepository(client).recordSwipe('u2', 'like');
    expect(matched, isTrue);
    verify(
      () => client.rpc(
        'record_swipe',
        params: {'p_target': 'u2', 'p_direction': 'like'},
      ),
    ).called(1);
  });

  test(
    'updateMyLocation sends p_lat/p_lng/p_area (area defaults null)',
    () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc('update_my_location', params: any(named: 'params')),
      ).thenAnswer((_) => rpcOk(null));
      await DiscoveryRepository(client).updateMyLocation(10.77, 106.70);
      verify(
        () => client.rpc(
          'update_my_location',
          params: {'p_lat': 10.77, 'p_lng': 106.70, 'p_area': null},
        ),
      ).called(1);
    },
  );

  group('getMatchProfile', () {
    test('maps a valid composite row into a Candidate', () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc('get_match_profile', params: any(named: 'params')),
      ).thenAnswer(
        (_) => rpcOk({
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
        }),
      );
      final result = await DiscoveryRepository(client).getMatchProfile('m1');
      expect(result, isNotNull);
      expect(result!.id, 'u2');
      expect(result.displayName, 'Linh');
      expect(result.sharedBaitu, ['song-chung']);
      expect(result.prompts.single['prompt_id'], 'p1');
      verify(
        () => client.rpc('get_match_profile', params: {'p_match': 'm1'}),
      ).called(1);
    });

    test('returns null when the RPC result is null (defensive)', () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc('get_match_profile', params: any(named: 'params')),
      ).thenAnswer((_) => rpcOk(null));
      final result = await DiscoveryRepository(client).getMatchProfile('m1');
      expect(result, isNull);
    });

    test(
      'returns null when the composite row is empty (other user soft-deleted)',
      () async {
        final client = MockSupabaseClient();
        when(
          () => client.rpc('get_match_profile', params: any(named: 'params')),
        ).thenAnswer(
          (_) => rpcOk({
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
          }),
        );
        final result = await DiscoveryRepository(client).getMatchProfile('m1');
        expect(result, isNull);
      },
    );

    test(
      'unwraps a List-shaped result (defensive against setof-style response)',
      () async {
        final client = MockSupabaseClient();
        when(
          () => client.rpc('get_match_profile', params: any(named: 'params')),
        ).thenAnswer(
          (_) => rpcOk([
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
          ]),
        );
        final result = await DiscoveryRepository(client).getMatchProfile('m1');
        expect(result, isNotNull);
        expect(result!.id, 'u2');
      },
    );
  });

  group('getLikesTeaser', () {
    /// Mirror photo_repository_test: stub `client.functions` + `client.storage.url`
    /// (the rebase step needs a base origin, like signedUrlsOf).
    (MockSupabaseClient, _MockFunctions) clientWithFns(String storageUrl) {
      final client = MockSupabaseClient();
      final fns = _MockFunctions();
      final storage = _MockStorage();
      when(() => client.functions).thenReturn(fns);
      when(() => client.storage).thenReturn(storage);
      when(() => storage.url).thenReturn(storageUrl);
      return (client, fns);
    }

    test(
      'maps likers and rebases the kong internal host to the client origin',
      () async {
        final (client, fns) = clientWithFns('http://10.0.2.2:54321/storage/v1');
        when(() => fns.invoke('likes-teaser')).thenAnswer(
          (_) async => FunctionResponse(
            data: {
              'likers': [
                {
                  // Edge builds URLs from its runtime SUPABASE_URL (kong:8000
                  // on local) — must come back rebased onto the client origin.
                  'teaser_url':
                      'http://kong:8000/storage/v1/object/sign/profile-photos/u9/teaser.jpg?token=abc',
                  'age': 24,
                  'verified': true,
                  'shared_genre': 'ballad',
                },
                {
                  // Liker without photos: teaser_url null stays null (no rebase).
                  'teaser_url': null,
                  'age': null,
                  'verified': false,
                  'shared_genre': null,
                },
              ],
            },
            status: 200,
          ),
        );

        final list = await DiscoveryRepository(client).getLikesTeaser();

        expect(list, hasLength(2));
        expect(
          list.first.teaserUrl,
          'http://10.0.2.2:54321/storage/v1/object/sign/profile-photos/u9/teaser.jpg?token=abc',
        );
        expect(list.first.age, 24);
        expect(list.first.verified, isTrue);
        expect(list.first.sharedGenre, 'ballad');
        expect(list.last.teaserUrl, isNull);
        expect(list.last.age, isNull);
        expect(list.last.verified, isFalse);
        expect(list.last.sharedGenre, isNull);
        verify(() => fns.invoke('likes-teaser')).called(1);
      },
    );

    test(
      'keeps an already-matching origin unchanged (prod no-op case)',
      () async {
        final (client, fns) = clientWithFns('http://10.0.2.2:54321/storage/v1');
        const url =
            'http://10.0.2.2:54321/storage/v1/object/sign/profile-photos/u9/teaser.jpg?token=abc';
        when(() => fns.invoke('likes-teaser')).thenAnswer(
          (_) async => FunctionResponse(
            data: {
              'likers': [
                {'teaser_url': url, 'age': 30, 'verified': false},
              ],
            },
            status: 200,
          ),
        );

        final list = await DiscoveryRepository(client).getLikesTeaser();

        expect(list.single.teaserUrl, url);
      },
    );

    test('returns [] when the response has no likers key', () async {
      final (client, fns) = clientWithFns('http://10.0.2.2:54321/storage/v1');
      when(() => fns.invoke('likes-teaser')).thenAnswer(
        (_) async => FunctionResponse(data: <String, dynamic>{}, status: 200),
      );

      final list = await DiscoveryRepository(client).getLikesTeaser();

      expect(list, isEmpty);
    });
  });
}
