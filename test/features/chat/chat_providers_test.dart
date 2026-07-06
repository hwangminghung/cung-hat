import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  test(
    'messageHistoryProvider reloads after its last listener is removed',
    () async {
      final repo = _MockChatRepository();
      when(() => repo.history('t1')).thenAnswer((_) async => <Message>[]);

      final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final first = container.listen(messageHistoryProvider('t1'), (_, _) {});
      await container.read(messageHistoryProvider('t1').future);
      first.close();
      await container.pump();

      final second = container.listen(messageHistoryProvider('t1'), (_, _) {});
      await container.read(messageHistoryProvider('t1').future);
      second.close();

      verify(() => repo.history('t1')).called(2);
    },
  );

  test(
    'keoMessageHistoryProvider reloads after its last listener is removed',
    () async {
      final repo = _MockChatRepository();
      when(() => repo.keoHistory('k1')).thenAnswer((_) async => <Message>[]);

      final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final first = container.listen(
        keoMessageHistoryProvider('k1'),
        (_, _) {},
      );
      await container.read(keoMessageHistoryProvider('k1').future);
      first.close();
      await container.pump();

      final second = container.listen(
        keoMessageHistoryProvider('k1'),
        (_, _) {},
      );
      await container.read(keoMessageHistoryProvider('k1').future);
      second.close();

      verify(() => repo.keoHistory('k1')).called(2);
    },
  );
}
