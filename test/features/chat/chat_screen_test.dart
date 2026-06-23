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
  testWidgets('typing a safe message and sending calls sendMessage', (tester) async {
    final repo = _MockRepo();
    when(() => repo.history(any())).thenAnswer((_) async => <Message>[]);
    when(() => repo.subscribe(any())).thenAnswer((_) => const Stream<Message>.empty());
    when(() => repo.markRead(any())).thenAnswer((_) async {});
    when(() => repo.sendMessage(any(), any())).thenAnswer((_) async => 'm1');
    await tester.pumpWidget(ProviderScope(
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: ChatScreen(matchId: 't1', otherName: 'Linh')),
    ));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'đi hát nhé');
    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pump();
    verify(() => repo.sendMessage('t1', 'đi hát nhé')).called(1);
  });
}
