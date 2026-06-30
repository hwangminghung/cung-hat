import 'dart:async';

import 'package:cung_hat/features/chat/domain/pending_chat_media.dart';
import 'package:cung_hat/features/chat/presentation/widgets/chat_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps only backend-supported media MIME types', () {
    expect(chatMediaTypeForMime('image/jpeg'), 'image');
    expect(chatMediaTypeForMime('image/png'), 'image');
    expect(chatMediaTypeForMime('image/webp'), 'image');
    expect(chatMediaTypeForMime('video/mp4'), 'video');
    expect(chatMediaTypeForMime('video/quicktime'), 'video');
  });

  test('rejects unsupported media MIME types', () {
    expect(chatMediaTypeForMime(null), isNull);
    expect(chatMediaTypeForMime('image/gif'), isNull);
    expect(chatMediaTypeForMime('image/heic'), isNull);
    expect(chatMediaTypeForMime('video/webm'), isNull);
    expect(chatMediaTypeForMime('application/octet-stream'), isNull);
  });

  testWidgets('sends trimmed text and clears the field on success', (
    tester,
  ) async {
    final sentMessages = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            onSendText: (text) async => sentMessages.add(text),
            onSendMedia: (PendingChatMedia media) async {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  di hat nhe  ');
    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pump();

    expect(sentMessages, ['di hat nhe']);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('preserves text when send is intentionally cancelled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            onSendText: (_) async => throw const ChatSendCancelled(),
            onSendMedia: (PendingChatMedia media) async {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  canh bao tien  ');
    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, '  canh bao tien  ');
    expect(textField.enabled, isTrue);
  });

  testWidgets('ignores empty text sends', (tester) async {
    var sendCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            onSendText: (_) async => sendCount++,
            onSendMedia: (PendingChatMedia media) async {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pump();

    expect(sendCount, 0);
  });

  testWidgets('disables text sending when composer is disabled', (
    tester,
  ) async {
    var sendCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            enabled: false,
            onSendText: (_) async => sendCount++,
            onSendMedia: (PendingChatMedia media) async {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pump();

    expect(sendCount, 0);
  });

  testWidgets('disables text field while sending', (tester) async {
    final sendCompleter = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            onSendText: (_) => sendCompleter.future,
            onSendMedia: (PendingChatMedia media) async {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pump();

    var textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);

    sendCompleter.complete();
    await tester.pump();

    textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isTrue);
  });

  testWidgets('shows attach and send controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            onSendText: (_) async {},
            onSendMedia: (PendingChatMedia media) async {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('attach_media_btn')), findsOneWidget);
    expect(find.byKey(const Key('send_btn')), findsOneWidget);
  });
}
