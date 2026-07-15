import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/providers/supabase_providers.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/presentation/chat_screen.dart';
import '../../support/supabase_mocks.dart';

class _MockChatRepo extends Mock implements ChatRepository {}

void main() {
  // [AUDIT M3] Lỗi tải history trước đây hiển thị y hệt "Chưa có tin nhắn"
  // (empty state) — user không phân biệt được lỗi mạng với thread trống và
  // không có đường thử lại.
  testWidgets('lỗi tải history → EmptyState + Thử lại refetch', (tester) async {
    final repo = _MockChatRepo();
    when(() => repo.markRead(any())).thenAnswer((_) async {});
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
          chatRepositoryProvider.overrideWithValue(repo),
          // StateError (Error) bỏ qua auto-retry backoff của Riverpod.
          messageHistoryProvider('t1').overrideWith((ref) {
            calls++;
            if (calls == 1) throw StateError('net');
            return Future.value(const <Message>[]);
          }),
          liveMessagesProvider(
            't1',
          ).overrideWith((ref) => const Stream<Message>.empty()),
        ],
        child: const MaterialApp(
          home: ChatScreen(matchId: 't1', otherName: 'Trang'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được tin nhắn'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không tải được tin nhắn'), findsNothing);
    expect(find.textContaining('Chưa có tin nhắn'), findsOneWidget);
  });
}
