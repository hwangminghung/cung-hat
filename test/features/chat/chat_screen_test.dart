import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/core/providers/supabase_providers.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/domain/message_attachment.dart';
import 'package:cung_hat/features/chat/presentation/chat_screen.dart';

class _MockRepo extends Mock implements ChatRepository {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

void main() {
  testWidgets('typing a safe message and sending calls sendMessage', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.history(any())).thenAnswer((_) async => <Message>[]);
    when(
      () => repo.subscribe(any()),
    ).thenAnswer((_) => const Stream<Message>.empty());
    when(() => repo.markRead(any())).thenAnswer((_) async {});
    when(() => repo.sendMessage(any(), any())).thenAnswer((_) async => 'm1');
    when(
      () => repo.signedMediaUrl(any(), any()),
    ).thenAnswer((_) async => 'https://example.test/media');
    when(() => repo.deleteMessage(any())).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: ChatScreen(matchId: 't1', otherName: 'Linh'),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'đi hát nhé');
    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pump();
    verify(() => repo.sendMessage('t1', 'đi hát nhé')).called(1);
  });
  testWidgets(
    'renders history image and long-pressing own message deletes it',
    (tester) async {
      final repo = _MockRepo();
      final client = _MockSupabaseClient();
      final auth = _MockAuth();
      const user = User(
        id: 'u1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-06-23T10:00:00Z',
      );
      const message = Message(
        id: 'm1',
        threadId: 't1',
        senderId: 'u1',
        kind: 'image',
        attachment: MessageAttachment(
          id: 'a1',
          messageId: 'm1',
          mediaType: 'image',
          bucketId: 'chat-media',
          objectPath: 'matches/t1/m1/image.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 123,
          status: 'ready',
        ),
        createdAt: '2026-06-23T10:00:00Z',
      );

      when(() => client.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(user);
      when(
        () => repo.history(any()),
      ).thenAnswer((_) async => <Message>[message]);
      when(
        () => repo.subscribe(any()),
      ).thenAnswer((_) => const Stream<Message>.empty());
      when(() => repo.markRead(any())).thenAnswer((_) async {});
      when(
        () => repo.signedMediaUrl(any(), any()),
      ).thenAnswer((_) async => 'https://example.test/media');
      when(() => repo.deleteMessage(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(repo),
            supabaseClientProvider.overrideWithValue(client),
          ],
          child: const MaterialApp(
            home: ChatScreen(matchId: 't1', otherName: 'Linh'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('image_media_bubble')), findsOneWidget);

      await tester.longPress(find.byKey(const Key('image_media_bubble')));
      await tester.pump();

      verify(() => repo.deleteMessage('m1')).called(1);
    },
  );
}
