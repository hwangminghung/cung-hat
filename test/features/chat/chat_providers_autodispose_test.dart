import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  test('messageHistoryProvider autoDispose: rewatch sau khi bo listener -> fetch lai', () async {
    final repo = _MockChatRepository();
    when(() => repo.history('m1')).thenAnswer((_) async => <Message>[]);
    final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final sub1 = container.listen(messageHistoryProvider('m1'), (_, _) {});
    await container.read(messageHistoryProvider('m1').future);
    verify(() => repo.history('m1')).called(1);

    sub1.close();
    // autoDispose huy state sau khi het listener (pump = doi scheduler dispose xong).
    await container.pump();

    final sub2 = container.listen(messageHistoryProvider('m1'), (_, _) {});
    await container.read(messageHistoryProvider('m1').future);
    verify(() => repo.history('m1')).called(1); // lan 2 (mocktail dem tu lan verify truoc)
    sub2.close();
  });

  test('keoMessageHistoryProvider autoDispose: rewatch -> fetch lai', () async {
    final repo = _MockChatRepository();
    when(() => repo.keoHistory('k1')).thenAnswer((_) async => <Message>[]);
    final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final sub1 = container.listen(keoMessageHistoryProvider('k1'), (_, _) {});
    await container.read(keoMessageHistoryProvider('k1').future);
    sub1.close();
    await container.pump();
    final sub2 = container.listen(keoMessageHistoryProvider('k1'), (_, _) {});
    await container.read(keoMessageHistoryProvider('k1').future);
    verify(() => repo.keoHistory('k1')).called(2);
    sub2.close();
  });

  // Nua con lai cua C-C1 (leak channel): stream provider phai autoDispose de
  // subscription bi cancel khi het listener (ChatRepository.onCancel go channel),
  // va subscribe LAI khi mo lai thread.
  test('liveMessagesProvider autoDispose: rewatch -> subscribe lai', () async {
    final repo = _MockChatRepository();
    when(() => repo.subscribe('m1'))
        .thenAnswer((_) => const Stream<Message>.empty());
    final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final sub1 = container.listen(liveMessagesProvider('m1'), (_, _) {});
    await container.pump();
    sub1.close();
    await container.pump();
    final sub2 = container.listen(liveMessagesProvider('m1'), (_, _) {});
    await container.pump();
    verify(() => repo.subscribe('m1')).called(2);
    sub2.close();
  });

  test('keoLiveMessagesProvider autoDispose: rewatch -> subscribe lai', () async {
    final repo = _MockChatRepository();
    when(() => repo.subscribeKeo('k1'))
        .thenAnswer((_) => const Stream<Message>.empty());
    final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final sub1 = container.listen(keoLiveMessagesProvider('k1'), (_, _) {});
    await container.pump();
    sub1.close();
    await container.pump();
    final sub2 = container.listen(keoLiveMessagesProvider('k1'), (_, _) {});
    await container.pump();
    verify(() => repo.subscribeKeo('k1')).called(2);
    sub2.close();
  });
}
