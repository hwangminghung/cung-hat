import 'package:supabase_flutter/supabase_flutter.dart';

const kPolicyVersion = 'v1';

/// Mot nguoi trong danh sach "Da chan" cua toi.
class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.displayName,
    required this.createdAt,
  });
  final String userId;

  /// null khi profile nguoi bi chan da bi xoa mem — UI hien 'Ẩn danh'.
  final String? displayName;
  final String createdAt;

  factory BlockedUser.fromJson(Map<String, dynamic> j) => BlockedUser(
    userId: j['blocked_id'] as String,
    displayName: j['display_name'] as String?,
    createdAt: j['created_at'] as String,
  );
}

class SettingsRepository {
  SettingsRepository(this._client);
  final SupabaseClient _client;

  /// [DEBT] /admin tung la route mo coi — khong loi vao nao tren UI. Tile
  /// Cai dat chi hien khi RPC nay tra true. Loi mang/RPC coi nhu khong phai
  /// admin: an tile la fallback an toan, console van vao duoc lan sau.
  Future<bool> isAdmin() async {
    try {
      final res = await _client.rpc('is_admin_self');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Danh sach nguoi TOI da chan, kem display_name (join qua security definer
  /// vi profile nguoi bi chan khong chac doc duoc qua RLS thuong).
  Future<List<BlockedUser>> myBlocks() async {
    final rows = await _client.rpc('get_my_blocks');
    return [
      for (final r in (rows as List))
        BlockedUser.fromJson(Map<String, dynamic>.from(r as Map)),
    ];
  }

  /// Bo chan = xoa row cua chinh minh (policy blocks_self FOR ALL). LUU Y
  /// T&S: match cu KHONG song lai — block_user da unmatch vinh vien; bo chan
  /// chi go rao chan discovery/keo tu gio tro di.
  Future<void> unblock(String blockedId) async {
    await _client.from('blocks').delete().eq('blocked_id', blockedId);
  }

  Future<Map<String, dynamic>> exportMyData() async {
    final res = await _client.rpc('export_my_data');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> withdrawConsent(String purpose) async {
    await _client.rpc(
      'record_consent',
      params: {
        'p_purpose': purpose,
        'p_granted': false,
        'p_policy_version': kPolicyVersion,
      },
    );
  }

  Future<void> grantConsent(String purpose) async {
    await _client.rpc(
      'record_consent',
      params: {
        'p_purpose': purpose,
        'p_granted': true,
        'p_policy_version': kPolicyVersion,
      },
    );
  }

  Future<void> deleteAccount() async {
    await _client.rpc('request_account_deletion');
  }

  /// Latest granted state per consent purpose (consents_self RLS allows reading own rows).
  Future<Map<String, bool>> myConsents() async {
    final rows = await _client
        .from('consents')
        .select('purpose, granted, granted_at')
        .order('granted_at');
    final out = <String, bool>{};
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      out[m['purpose'] as String] =
          m['granted'] as bool; // later rows (newer) overwrite → latest wins
    }
    return out;
  }
}
