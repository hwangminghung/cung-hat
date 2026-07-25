import 'package:supabase_flutter/supabase_flutter.dart';

class PushService {
  PushService(this._client);
  final SupabaseClient _client;

  Future<void> registerToken(String token, String platform) async {
    await _client.rpc(
      'register_device_token',
      params: {'p_token': token, 'p_platform': platform},
    );
  }
}
