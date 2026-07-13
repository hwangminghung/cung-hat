import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/presentation/chat_screen.dart';

class _MockRepo extends Mock implements ChatRepository {}

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

  testWidgets('chat 1-1 chèn divider ngày + giờ HH:mm trên bubble', (
    tester,
  ) async {
    final repo = _MockRepo();
    const isoA = '2026-07-05T10:00:00Z';
    const isoB = '2026-07-06T11:30:00Z';
    when(() => repo.history(any())).thenAnswer(
      (_) async => const [
        Message(
          id: 'm1',
          threadId: 't1',
          senderId: 'u2',
          body: 'hom qua',
          createdAt: isoA,
        ),
        Message(
          id: 'm2',
          threadId: 't1',
          senderId: 'u2',
          body: 'hom nay',
          createdAt: isoB,
        ),
      ],
    );
    when(
      () => repo.subscribe(any()),
    ).thenAnswer((_) => const Stream<Message>.empty());
    when(() => repo.markRead(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: ChatScreen(matchId: 't1', otherName: 'Linh'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    String two(int v) => v.toString().padLeft(2, '0');
    final a = DateTime.parse(isoA).toLocal();
    final b = DateTime.parse(isoB).toLocal();
    expect(find.text('${a.day}/${a.month}'), findsOneWidget);
    expect(find.text('${b.day}/${b.month}'), findsOneWidget);
    expect(find.text('${two(a.hour)}:${two(a.minute)}'), findsOneWidget);
    expect(find.text('${two(b.hour)}:${two(b.minute)}'), findsOneWidget);
  });
}
