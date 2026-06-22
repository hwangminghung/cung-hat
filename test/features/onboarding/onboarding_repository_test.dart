import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/onboarding/data/onboarding_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('recordConsent calls record_consent with params', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('record_consent', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(null));
    await OnboardingRepository(client)
        .recordConsent(purpose: 'location', granted: true, policyVersion: 'v1');
    verify(() => client.rpc('record_consent', params: {
      'p_purpose': 'location', 'p_granted': true, 'p_policy_version': 'v1',
    })).called(1);
  });

  test('saveTaste calls upsert_my_taste with arrays', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('upsert_my_taste', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(null));
    await OnboardingRepository(client)
        .saveTaste(genreIds: ['vpop'], artistIds: ['my_tam'], songIds: ['s2']);
    verify(() => client.rpc('upsert_my_taste', params: {
      'p_genre_ids': ['vpop'], 'p_artist_ids': ['my_tam'], 'p_song_ids': ['s2'],
    })).called(1);
  });
}
