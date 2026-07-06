import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/pending_chat_media.dart';
import 'chat_media_uploader.dart';
import '../domain/message.dart';
import '../domain/message_attachment.dart';

/// Converts a Supabase broadcast frame ({type,event,payload}) to a [Message].
/// The DB trigger's jsonb is nested under the frame's `payload` key.
Message messageFromBroadcast(Map<String, dynamic> frame) {
  final data = Map<String, dynamic>.from(frame['payload'] as Map);
  return Message.fromJson(data);
}

class ChatRepository {
  ChatRepository(this._client, {ChatMediaUploader? uploader})
    : _uploader = uploader ?? SupabaseChatMediaUploader(_client);

  final SupabaseClient _client;
  final ChatMediaUploader _uploader;

  Future<String> sendMessage(String threadId, String body) async {
    final id = await _client.rpc(
      'send_message',
      params: {'p_thread': threadId, 'p_body': body},
    );
    return id as String;
  }

  Future<void> markRead(String threadId) async {
    await _client.rpc('mark_match_read', params: {'p_thread': threadId});
  }

  Future<String> sendMatchMedia(String threadId, PendingChatMedia media) {
    return _sendMedia(threadType: 'match', threadId: threadId, media: media);
  }

  Future<List<Message>> history(String threadId) async {
    return _history(threadType: 'match', threadId: threadId);
  }

  /// Live messages on the private topic match:{threadId}.
  Stream<Message> subscribe(String threadId) {
    final ch = _client.channel(
      'match:$threadId',
      opts: const RealtimeChannelConfig(private: true),
    );
    final controller = StreamController<Message>();
    ch
        .onBroadcast(
          event: 'new_message',
          callback: (payload) {
            try {
              controller.add(
                messageFromBroadcast(Map<String, dynamic>.from(payload)),
              );
            } catch (e, st) {
              controller.addError(e, st);
            }
          },
        )
        .subscribe();
    controller.onCancel = () => _client.removeChannel(ch);
    return controller.stream;
  }

  Future<String> sendKeoMessage(String keoId, String body) async {
    final id = await _client.rpc(
      'send_keo_message',
      params: {'p_keo': keoId, 'p_body': body},
    );
    return id as String;
  }

  Future<void> markKeoRead(String keoId) async {
    await _client.rpc('mark_keo_read', params: {'p_keo': keoId});
  }

  Future<String> sendKeoMedia(String keoId, PendingChatMedia media) {
    return _sendMedia(threadType: 'keo', threadId: keoId, media: media);
  }

  Future<List<Message>> keoHistory(String keoId) async {
    return _history(threadType: 'keo', threadId: keoId);
  }

  Future<List<Message>> _history({
    required String threadType,
    required String threadId,
  }) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('thread_type', threadType)
        .eq('thread_id', threadId)
        .order('created_at');
    final messages = (rows as List)
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final mediaMessageIds = [
      for (final message in messages)
        if (message.kind != 'text') message.id,
    ];
    if (mediaMessageIds.isEmpty) return messages;

    final attachmentRows = await _client
        .from('message_attachments')
        .select()
        .eq('thread_type', threadType)
        .eq('thread_id', threadId)
        .inFilter('message_id', mediaMessageIds);
    final attachmentsByMessageId = <String, MessageAttachment>{};
    for (final row in attachmentRows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final messageId = map['message_id'] as String?;
      if (messageId != null) {
        attachmentsByMessageId[messageId] = MessageAttachment.fromJson(map);
      }
    }

    return [
      for (final message in messages)
        if (attachmentsByMessageId[message.id] case final attachment?)
          message.copyWith(attachment: attachment)
        else
          message,
    ];
  }

  /// Live messages on the private topic keo:{keoId}.
  Stream<Message> subscribeKeo(String keoId) {
    final ch = _client.channel(
      'keo:$keoId',
      opts: const RealtimeChannelConfig(private: true),
    );
    final controller = StreamController<Message>();
    ch
        .onBroadcast(
          event: 'new_message',
          callback: (payload) {
            try {
              controller.add(
                messageFromBroadcast(Map<String, dynamic>.from(payload)),
              );
            } catch (e, st) {
              controller.addError(e, st);
            }
          },
        )
        .subscribe();
    controller.onCancel = () => _client.removeChannel(ch);
    return controller.stream;
  }

  Future<String> _sendMedia({
    required String threadType,
    required String threadId,
    required PendingChatMedia media,
  }) async {
    final upload =
        await _client.rpc(
              'create_message_attachment',
              params: {
                'p_thread_type': threadType,
                'p_thread': threadId,
                'p_media_type': media.mediaType,
                'p_mime_type': media.mimeType,
                'p_size_bytes': media.sizeBytes,
                'p_width': media.width,
                'p_height': media.height,
                'p_duration_ms': media.durationMs,
              },
            )
            as Map;
    final uploadMap = Map<String, dynamic>.from(upload);
    final attachmentId = uploadMap['id'] as String;
    final bucketId = uploadMap['bucket_id'] as String;
    final objectPath = uploadMap['object_path'] as String;

    await _uploader.upload(
      bucketId: bucketId,
      objectPath: objectPath,
      file: media.file,
      mimeType: media.mimeType,
    );

    final id = await _client.rpc(
      'send_media_message',
      params: {'p_attachment': attachmentId},
    );
    return id as String;
  }

  Future<void> deleteMessage(String messageId) async {
    await _client.rpc('delete_message', params: {'p_message': messageId});
  }

  Future<String> signedMediaUrl(String bucketId, String objectPath) {
    return _uploader.signedUrl(bucketId: bucketId, objectPath: objectPath);
  }
}
