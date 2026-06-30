import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message JSON', () {
    test('parses text message without attachment', () {
      final message = Message.fromJson({
        'id': 'm1',
        'thread_id': 't1',
        'sender_id': 'u1',
        'body': 'hello',
        'kind': 'text',
        'hidden': false,
        'attachment': null,
        'created_at': '2026-06-23T10:00:00Z',
      });

      expect(message.id, 'm1');
      expect(message.threadId, 't1');
      expect(message.senderId, 'u1');
      expect(message.body, 'hello');
      expect(message.kind, 'text');
      expect(message.hidden, isFalse);
      expect(message.attachment, isNull);
      expect(message.createdAt, '2026-06-23T10:00:00Z');
    });

    test('parses image message with nested attachment', () {
      final message = Message.fromJson({
        'id': 'm2',
        'thread_id': 't1',
        'sender_id': 'u2',
        'body': null,
        'kind': 'image',
        'hidden': false,
        'attachment': {
          'id': 'a1',
          'message_id': 'm2',
          'media_type': 'image',
          'bucket_id': 'chat-media',
          'object_path': 'threads/t1/m2/photo.jpg',
          'thumbnail_bucket_id': 'chat-thumbnails',
          'thumbnail_path': 'threads/t1/m2/photo-thumb.jpg',
          'mime_type': 'image/jpeg',
          'size_bytes': 123456,
          'width': 1200,
          'height': 800,
          'duration_ms': null,
          'status': 'ready',
        },
        'created_at': '2026-06-23T10:01:00Z',
      });

      expect(message.body, isNull);
      expect(message.kind, 'image');
      expect(message.attachment, isNotNull);
      expect(message.attachment!.objectPath, 'threads/t1/m2/photo.jpg');
      expect(message.attachment!.sizeBytes, 123456);
    });

    test('defaults legacy message fields when missing', () {
      final message = Message.fromJson({
        'id': 'm3',
        'thread_id': 't2',
        'sender_id': 'u3',
        'body': 'legacy',
        'created_at': '2026-06-23T10:02:00Z',
      });

      expect(message.kind, 'text');
      expect(message.hidden, isFalse);
      expect(message.attachment, isNull);
    });
  });
}
