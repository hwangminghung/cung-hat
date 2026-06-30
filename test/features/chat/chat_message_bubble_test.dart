import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/domain/message_attachment.dart';
import 'package:cung_hat/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:cung_hat/features/chat/presentation/widgets/media_message_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders text message body', (tester) async {
    await tester.pumpWidget(_wrap(_bubble(message: _message(body: 'hello'))));

    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('renders deleted tombstone', (tester) async {
    await tester.pumpWidget(
      _wrap(_bubble(message: _message(body: 'secret', hidden: true))),
    );

    expect(find.text('Tin da xoa'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Tin da xoa'));
    expect(text.style?.fontStyle, FontStyle.italic);
  });

  testWidgets('renders image media shell after URL resolves', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _bubble(
          message: _message(
            kind: 'image',
            attachment: _attachment(mediaType: 'image'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('image_media_bubble')), findsOneWidget);
  });

  testWidgets('renders video media shell after URL resolves', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _bubble(
          message: _message(
            kind: 'video',
            attachment: _attachment(mediaType: 'video'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('video_media_bubble')), findsOneWidget);
  });

  testWidgets('caches resolved media URL across parent rebuilds', (
    tester,
  ) async {
    var resolveCount = 0;
    final attachment = _attachment(mediaType: 'image');

    Future<String> resolveMediaUrl(String bucketId, String objectPath) async {
      resolveCount++;
      return 'https://example.com/$objectPath';
    }

    await tester.pumpWidget(
      _wrap(
        MediaMessageView(
          attachment: attachment,
          resolveMediaUrl: resolveMediaUrl,
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      _wrap(
        MediaMessageView(
          attachment: attachment,
          resolveMediaUrl: resolveMediaUrl,
        ),
      ),
    );
    await tester.pump();

    expect(resolveCount, 1);
  });

  testWidgets('re-resolves media URL when object path changes', (tester) async {
    var resolveCount = 0;
    final attachment = _attachment(mediaType: 'image');

    Future<String> resolveMediaUrl(String bucketId, String objectPath) async {
      resolveCount++;
      return 'https://example.com/$objectPath';
    }

    await tester.pumpWidget(
      _wrap(
        MediaMessageView(
          attachment: attachment,
          resolveMediaUrl: resolveMediaUrl,
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      _wrap(
        MediaMessageView(
          attachment: _attachment(
            mediaType: 'image',
            objectPath: 'threads/t1/m1/changed',
          ),
          resolveMediaUrl: resolveMediaUrl,
        ),
      ),
    );
    await tester.pump();

    expect(resolveCount, 2);
  });

  testWidgets('long press delete only fires for mine messages', (tester) async {
    var deleteCount = 0;

    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            _bubble(
              key: const Key('mine_message'),
              mine: true,
              message: _message(id: 'mine', body: 'mine'),
              onDelete: () => deleteCount++,
            ),
            _bubble(
              key: const Key('their_message'),
              mine: false,
              message: _message(id: 'theirs', body: 'theirs'),
              onDelete: () => deleteCount++,
            ),
          ],
        ),
      ),
    );

    await tester.longPress(find.text('mine'));
    await tester.longPress(find.text('theirs'));

    expect(deleteCount, 1);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

Widget _bubble({
  Key? key,
  required Message message,
  bool mine = false,
  VoidCallback? onDelete,
}) {
  return ChatMessageBubble(
    key: key,
    message: message,
    mine: mine,
    resolveMediaUrl: (_, _) async => 'https://example.com/media.jpg',
    onDelete: onDelete,
  );
}

Message _message({
  String id = 'm1',
  String? body,
  String kind = 'text',
  bool hidden = false,
  MessageAttachment? attachment,
}) {
  return Message(
    id: id,
    threadId: 't1',
    senderId: 'u1',
    body: body,
    kind: kind,
    hidden: hidden,
    attachment: attachment,
    createdAt: '2026-06-23T10:00:00Z',
  );
}

MessageAttachment _attachment({
  required String mediaType,
  String objectPath = 'threads/t1/m1/media',
}) {
  return MessageAttachment(
    id: 'a1',
    messageId: 'm1',
    mediaType: mediaType,
    bucketId: 'chat-media',
    objectPath: objectPath,
    mimeType: '$mediaType/test',
    sizeBytes: 123,
    status: 'ready',
  );
}
