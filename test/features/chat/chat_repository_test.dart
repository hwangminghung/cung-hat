import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/data/chat_media_uploader.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/pending_chat_media.dart';
import '../../support/supabase_mocks.dart';

class _FakeUpload {
  const _FakeUpload({
    required this.bucketId,
    required this.objectPath,
    required this.file,
    required this.mimeType,
  });

  final String bucketId;
  final String objectPath;
  final File file;
  final String mimeType;
}

class _FakeUploader implements ChatMediaUploader {
  _FakeUploader({this.onUpload, this.onUploadFuture});

  final void Function()? onUpload;
  final Future<void> Function()? onUploadFuture;
  final uploaded = <_FakeUpload>[];

  @override
  Future<String> signedUrl({
    required String bucketId,
    required String objectPath,
    int expiresInSeconds = 600,
  }) async {
    return 'signed:$bucketId/$objectPath';
  }

  @override
  Future<void> upload({
    required String bucketId,
    required String objectPath,
    required File file,
    required String mimeType,
  }) async {
    onUpload?.call();
    uploaded.add(
      _FakeUpload(
        bucketId: bucketId,
        objectPath: objectPath,
        file: file,
        mimeType: mimeType,
      ),
    );
    final uploadFuture = onUploadFuture;
    if (uploadFuture != null) {
      await uploadFuture();
    }
  }
}

void main() {
  test(
    'sendMessage calls send_message RPC with thread + body and returns id',
    () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc('send_message', params: any(named: 'params')),
      ).thenAnswer((_) => rpcOk('m1'));
      final id = await ChatRepository(client).sendMessage('t1', 'hello');
      expect(id, 'm1');
      verify(
        () => client.rpc(
          'send_message',
          params: {'p_thread': 't1', 'p_body': 'hello'},
        ),
      ).called(1);
    },
  );

  test('messageFromBroadcast unwraps the frame payload envelope', () {
    final frame = <String, dynamic>{
      'type': 'broadcast',
      'event': 'new_message',
      'payload': {
        'id': 'm1',
        'thread_id': 't1',
        'sender_id': 'u2',
        'body': 'xin chào',
        'created_at': '2026-06-23T10:00:00Z',
      },
    };
    final msg = messageFromBroadcast(frame);
    expect(msg.id, 'm1');
    expect(msg.threadId, 't1');
    expect(msg.senderId, 'u2');
    expect(msg.body, 'xin chào');
  });

  test(
    'sendMatchMedia creates pending attachment, uploads, then sends media message',
    () async {
      final events = <String>[];
      final uploadCompleter = Completer<void>();
      final client = MockSupabaseClient();
      final uploader = _FakeUploader(
        onUpload: () => events.add('upload'),
        onUploadFuture: () => uploadCompleter.future,
      );
      final file = File('test/fixtures/chat-image.jpg');
      when(
        () => client.rpc(
          'create_message_attachment',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) {
        events.add('create');
        return rpcOk({
          'id': 'a1',
          'bucket_id': 'chat-media',
          'object_path': 'matches/t1/a1.jpg',
        });
      });
      when(
        () => client.rpc('send_media_message', params: any(named: 'params')),
      ).thenAnswer((_) {
        events.add('send');
        return rpcOk('m-media');
      });

      final sendFuture = ChatRepository(client, uploader: uploader)
          .sendMatchMedia(
            't1',
            PendingChatMedia(
              file: file,
              mediaType: 'image',
              mimeType: 'image/jpeg',
              sizeBytes: 100,
              width: 10,
              height: 10,
            ),
          );

      await Future<void>.delayed(Duration.zero);

      expect(events, ['create', 'upload']);
      verifyNever(
        () => client.rpc('send_media_message', params: any(named: 'params')),
      );

      uploadCompleter.complete();
      final id = await sendFuture;

      expect(id, 'm-media');
      verify(
        () => client.rpc(
          'create_message_attachment',
          params: {
            'p_thread_type': 'match',
            'p_thread': 't1',
            'p_media_type': 'image',
            'p_mime_type': 'image/jpeg',
            'p_size_bytes': 100,
            'p_width': 10,
            'p_height': 10,
            'p_duration_ms': null,
          },
        ),
      ).called(1);
      expect(uploader.uploaded, hasLength(1));
      expect(uploader.uploaded.single.bucketId, 'chat-media');
      expect(uploader.uploaded.single.objectPath, 'matches/t1/a1.jpg');
      expect(uploader.uploaded.single.file, file);
      expect(uploader.uploaded.single.mimeType, 'image/jpeg');
      verify(
        () => client.rpc('send_media_message', params: {'p_attachment': 'a1'}),
      ).called(1);
      expect(events, ['create', 'upload', 'send']);
    },
  );

  test(
    'sendMatchMedia does not send media message when upload fails',
    () async {
      final events = <String>[];
      final client = MockSupabaseClient();
      final uploader = _FakeUploader(
        onUpload: () => events.add('upload'),
        onUploadFuture: () async => throw StateError('upload failed'),
      );
      when(
        () => client.rpc(
          'create_message_attachment',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) {
        events.add('create');
        return rpcOk({
          'id': 'a1',
          'bucket_id': 'chat-media',
          'object_path': 'matches/t1/a1.jpg',
        });
      });
      when(
        () => client.rpc('send_media_message', params: any(named: 'params')),
      ).thenAnswer((_) {
        events.add('send');
        return rpcOk('m-media');
      });

      final sendFuture = ChatRepository(client, uploader: uploader)
          .sendMatchMedia(
            't1',
            PendingChatMedia(
              file: File('test/fixtures/chat-image.jpg'),
              mediaType: 'image',
              mimeType: 'image/jpeg',
              sizeBytes: 100,
            ),
          );

      await expectLater(sendFuture, throwsA(isA<StateError>()));
      expect(events, ['create', 'upload']);
      verifyNever(
        () => client.rpc('send_media_message', params: any(named: 'params')),
      );
    },
  );

  test('signedMediaUrl delegates to uploader', () async {
    final client = MockSupabaseClient();
    final uploader = _FakeUploader();

    final url = await ChatRepository(
      client,
      uploader: uploader,
    ).signedMediaUrl('chat-media', 'matches/t1/a1.jpg');

    expect(url, 'signed:chat-media/matches/t1/a1.jpg');
  });
}
