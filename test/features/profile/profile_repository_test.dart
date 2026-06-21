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
}
