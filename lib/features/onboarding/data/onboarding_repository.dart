import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingRepository {
  OnboardingRepository(this._client);
  final SupabaseClient _client;

  Future<void> recordConsent({
    required String purpose,
    required bool granted,
    required String policyVersion,
  }) async {
    await _client.rpc('record_consent', params: {
      'p_purpose': purpose,
      'p_granted': granted,
      'p_policy_version': policyVersion,
    });
  }

  Future<void> saveTaste({
    required List<String> genreIds,
    required List<String> artistIds,
    required List<String> songIds,
  }) async {
    await _client.rpc('upsert_my_taste', params: {
      'p_genre_ids': genreIds,
      'p_artist_ids': artistIds,
      'p_song_ids': songIds,
    });
  }
}
