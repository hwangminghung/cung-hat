import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/profile/data/profile_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('getMyProfile calls the get_my_profile RPC and maps result', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_my_profile')).thenAnswer((_) => rpcOk({
          'id': 'u1',
          'display_name': 'Mai',
          'age_verified': true,
          'language': 'vi',
        }));
    final repo = ProfileRepository(client);
    final p = await repo.getMyProfile();
    expect(p!.displayName, 'Mai');
    verify(() => client.rpc('get_my_profile')).called(1);
  });

  test('getMyTasteCounts maps jsonb lists to counts', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_my_taste')).thenAnswer((_) => rpcOk({
          'genres': ['pop', 'rock', 'ballad'],
          'artists': ['son_tung'],
          'baitu': ['s1', 's2', 's3'],
        }));
    final repo = ProfileRepository(client);
    final taste = await repo.getMyTasteCounts();
    expect(taste.genres, 3);
    expect(taste.artists, 1);
    expect(taste.baitu, 3);
    verify(() => client.rpc('get_my_taste')).called(1);
  });

  test('getMyTasteCounts treats null lists as 0', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_my_taste')).thenAnswer((_) => rpcOk({
          'genres': null,
          'artists': null,
          'baitu': null,
        }));
    final repo = ProfileRepository(client);
    final taste = await repo.getMyTasteCounts();
    expect(taste.genres, 0);
    expect(taste.artists, 0);
    expect(taste.baitu, 0);
  });
}
