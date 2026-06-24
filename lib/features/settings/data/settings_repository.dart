import 'package:supabase_flutter/supabase_flutter.dart';

const kPolicyVersion = 'v1';

class SettingsRepository {
  SettingsRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> exportMyData() async {
    final res = await _client.rpc('export_my_data');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> withdrawConsent(String purpose) async {
    await _client.rpc('record_consent',
        params: {'p_purpose': purpose, 'p_granted': false, 'p_policy_version': kPolicyVersion});
  }

  Future<void> grantConsent(String purpose) async {
    await _client.rpc('record_consent',
        params: {'p_purpose': purpose, 'p_granted': true, 'p_policy_version': kPolicyVersion});
  }

  Future<void> deleteAccount() async {
    await _client.rpc('request_account_deletion');
  }

  /// Latest granted state per consent purpose (consents_self RLS allows reading own rows).
  Future<Map<String, bool>> myConsents() async {
    final rows = await _client.from('consents').select('purpose, granted, granted_at').order('granted_at');
    final out = <String, bool>{};
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      out[m['purpose'] as String] = m['granted'] as bool; // later rows (newer) overwrite → latest wins
    }
    return out;
  }
}
