import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile.dart';
import '../domain/profile_completion.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<Profile?> getMyProfile() async {
    final res = await _client.rpc('get_my_profile');
    if (res == null) return null;
    final map = res is List ? (res.isEmpty ? null : res.first) : res;
    return map == null ? null : Profile.fromJson(Map<String, dynamic>.from(map as Map));
  }

  Future<Profile> upsertMyProfile(Profile p) async {
    final res = await _client.rpc('upsert_my_profile', params: {
      'p_display_name': p.displayName,
      'p_full_name': p.fullName,
      'p_dob': p.dob,
      'p_bio': p.bio,
      'p_language': p.language,
    });
    final map = res is List ? res.first : res;
    return Profile.fromJson(Map<String, dynamic>.from(map as Map));
  }

  Future<void> setMyPrompts(List<Map<String, String>> prompts) async {
    await _client.rpc('set_my_prompts', params: {'p_prompts': prompts});
  }

  Future<TasteCounts> getMyTasteCounts() async {
    final res = await _client.rpc('get_my_taste');
    final map = Map<String, dynamic>.from(res as Map);
    int count(String key) => (map[key] as List?)?.length ?? 0;
    return TasteCounts(count('genres'), count('artists'), count('baitu'));
  }

  /// SONG ID bài tủ của chính mình ('s1'..) — cho sheet "Gửi bài tủ" trong chat.
  Future<List<String>> getMyBaituIds() async {
    final res = await _client.rpc('get_my_taste');
    final map = Map<String, dynamic>.from(res as Map);
    return ((map['baitu'] as List?) ?? const []).cast<String>();
  }
}
