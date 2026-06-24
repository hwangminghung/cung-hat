import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/chat_repository.dart';
import '../domain/message.dart';

final chatRepositoryProvider =
    Provider((ref) => ChatRepository(ref.watch(supabaseClientProvider)));

final messageHistoryProvider = FutureProvider.family<List<Message>, String>(
    (ref, threadId) => ref.watch(chatRepositoryProvider).history(threadId));

final liveMessagesProvider = StreamProvider.family<Message, String>((ref, threadId) {
  return ref.watch(chatRepositoryProvider).subscribe(threadId);
});

final keoMessageHistoryProvider = FutureProvider.family<List<Message>, String>(
    (ref, keoId) => ref.watch(chatRepositoryProvider).keoHistory(keoId));

final keoLiveMessagesProvider = StreamProvider.family<Message, String>((ref, keoId) {
  return ref.watch(chatRepositoryProvider).subscribeKeo(keoId);
});
