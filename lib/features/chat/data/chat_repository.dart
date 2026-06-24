import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/message.dart';

/// Converts a Supabase broadcast frame ({type,event,payload}) to a [Message].
/// The DB trigger's jsonb is nested under the frame's `payload` key.
Message messageFromBroadcast(Map<String, dynamic> frame) {
  final data = Map<String, dynamic>.from(frame['payload'] as Map);
  return Message.fromJson(data);
}

class ChatRepository {
  ChatRepository(this._client);
  final SupabaseClient _client;

  Future<String> sendMessage(String threadId, String body) async {
    final id = await _client.rpc('send_message',
        params: {'p_thread': threadId, 'p_body': body});
    return id as String;
  }

  Future<void> markRead(String threadId) async {
    await _client.rpc('mark_match_read', params: {'p_thread': threadId});
  }

  Future<List<Message>> history(String threadId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('thread_type', 'match')
        .eq('thread_id', threadId)
        .order('created_at');
    return (rows as List)
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Live messages on the private topic match:{threadId}.
  Stream<Message> subscribe(String threadId) {
    final ch = _client.channel('match:$threadId',
        opts: const RealtimeChannelConfig(private: true));
    final controller = StreamController<Message>();
    ch.onBroadcast(event: 'new_message', callback: (payload) {
      try {
        controller.add(messageFromBroadcast(Map<String, dynamic>.from(payload)));
      } catch (e, st) {
        controller.addError(e, st);
      }
    }).subscribe();
    controller.onCancel = () => _client.removeChannel(ch);
    return controller.stream;
  }
}
