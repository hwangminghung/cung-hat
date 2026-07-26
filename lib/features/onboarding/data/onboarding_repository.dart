import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingRepository {
  OnboardingRepository(this._client);
  final SupabaseClient _client;

  /// Ghi TRỌN onboarding trong một transaction phía Postgres.
  ///
  /// [AUDIT P1-2] Trước đây client chạy ba lượt RPC rời nhau (upsert_my_profile
  /// → n× record_consent → upsert_my_taste). Rớt mạng giữa chừng để lại row
  /// profiles nhưng thiếu consent (rủi ro PDPL) và thiếu taste (deck rỗng),
  /// trong khi router chỉ nhìn "có profile" nên thả user vào app không đường
  /// quay lại. Thân hàm plpgsql là một transaction: bước sau nổ thì bước trước
  /// bị rollback.
  Future<void> completeOnboarding({
    required String displayName,
    required String fullName,
    required String dob,
    required String bio,
    required String language,
    required Map<String, bool> consents,
    required String policyVersion,
    required List<String> genreIds,
    required List<String> artistIds,
    required List<String> songIds,
  }) async {
    await _client.rpc(
      'complete_onboarding',
      params: {
        'p_display_name': displayName,
        'p_full_name': fullName,
        'p_dob': dob,
        'p_bio': bio,
        'p_language': language,
        'p_consents': consents,
        'p_policy_version': policyVersion,
        'p_genre_ids': genreIds,
        'p_artist_ids': artistIds,
        'p_song_ids': songIds,
      },
    );
  }
}
