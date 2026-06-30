import 'package:cung_hat/features/chat/domain/pending_chat_media.dart';
import 'package:cung_hat/features/chat/presentation/widgets/chat_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sends trimmed text and clears the field on success', (tester) async {
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

  testWidgets('disables text sending when composer is disabled', (tester) async {
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
