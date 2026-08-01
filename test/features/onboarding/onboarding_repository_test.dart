import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/onboarding/data/onboarding_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  // [AUDIT P1-2] Ba lượt RPC rời nhau (profile → consent → taste) sinh được
  // tài khoản nửa vời khi rớt mạng giữa chừng. Nay chỉ còn MỘT RPC chạy trong
  // một transaction phía Postgres.
  test('completeOnboarding gọi complete_onboarding với đủ tham số', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('complete_onboarding', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk(null));

    await OnboardingRepository(client).completeOnboarding(
      displayName: 'Mai',
      fullName: 'Tran Mai',
      dob: '2000-01-01',
      bio: 'hi',
      language: 'vi',
      consents: const {'matching': true, 'marketing': false},
      policyVersion: 'v1',
      genreIds: const ['vpop'],
      artistIds: const ['my_tam'],
      songIds: const ['s2'],
    );

    verify(
      () => client.rpc(
        'complete_onboarding',
        params: {
          'p_display_name': 'Mai',
          'p_full_name': 'Tran Mai',
          'p_dob': '2000-01-01',
          'p_bio': 'hi',
          'p_language': 'vi',
          'p_consents': {'matching': true, 'marketing': false},
          'p_policy_version': 'v1',
          'p_genre_ids': ['vpop'],
          'p_artist_ids': ['my_tam'],
          'p_song_ids': ['s2'],
        },
      ),
    ).called(1);
  });
}
