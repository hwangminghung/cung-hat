import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/presentation/chat_screen.dart';

class _MockRepo extends Mock implements ChatRepository {}

/// [UI-AUDIT] Chat rỗng: 3 chip gợi ý bấm được + nút gửi disable khi ô trống.
void main() {
  Future<_MockRepo> pumpEmptyChat(WidgetTester tester) async {
    final repo = _MockRepo();
    when(() => repo.history(any())).thenAnswer((_) async => <Message>[]);
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
    return repo;
  }

  testWidgets('chat rỗng hiện đủ 3 chip gợi ý', (tester) async {
    await pumpEmptyChat(tester);
    expect(find.byKey(const Key('chat_sugg_baitu')), findsOneWidget);
    expect(find.byKey(const Key('chat_sugg_taste')), findsOneWidget);
    expect(find.byKey(const Key('chat_sugg_invite')), findsOneWidget);
  });

  testWidgets('tap "Hỏi gu nhạc" → điền template vào ô nhập (chưa gửi)', (
    tester,
  ) async {
    await pumpEmptyChat(tester);
    await tester.tap(find.byKey(const Key('chat_sugg_taste')));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, contains('Gu nhạc của bạn là gì?'));
  });

  testWidgets('ô trống → nút gửi disable; gõ chữ → enable', (tester) async {
    await pumpEmptyChat(tester);

    IconButton send() =>
        tester.widget<IconButton>(find.byKey(const Key('send_btn')));
    expect(send().onPressed, isNull, reason: 'ô trống phải disable nút gửi');

    await tester.enterText(find.byType(TextField), 'hát không?');
    await tester.pump();
    expect(send().onPressed, isNotNull);

    // Toàn khoảng trắng vẫn tính là trống.
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(send().onPressed, isNull);
  });
}
