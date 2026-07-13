import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/domain/keo_member.dart';
import 'package:cung_hat/features/keo/presentation/keo_chat_screen.dart';
import '../../support/supabase_mocks.dart';

class _MockChatRepo extends Mock implements ChatRepository {}

void main() {
  test('sendKeoMessage calls send_keo_message RPC', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('send_keo_message', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk('m1'));
    final id = await ChatRepository(client).sendKeoMessage('k1', 'hi nhóm');
    expect(id, 'm1');
    verify(() => client.rpc('send_keo_message',
        params: {'p_keo': 'k1', 'p_body': 'hi nhóm'})).called(1);
  });

  testWidgets(
    'chat nhóm hiện subtitle tên kèo + tên người gửi trên bubble người khác',
    (tester) async {
      final repo = _MockChatRepo();
      when(() => repo.markKeoRead('k1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(repo),
            keoMessageHistoryProvider('k1').overrideWith(
              (ref) async => const [
                Message(
                  id: 'msg1',
                  threadId: 'k1',
                  senderId: 'linh-id',
                  body: 'Toi nay hat nhe',
                  createdAt: '2026-07-13T10:00:00Z',
                ),
              ],
            ),
            keoLiveMessagesProvider('k1').overrideWith(
              (ref) => const Stream<Message>.empty(),
            ),
            keoHeaderProvider('k1').overrideWith(
              (ref) async => const Keo(
                id: 'k1',
                title: 'Kèo demo tối nay',
                status: 'planning',
              ),
            ),
            keoRosterProvider('k1').overrideWith(
              (ref) async => const [
                KeoMember(
                  userId: 'linh-id',
                  displayName: 'QA Linh Ballad',
                  role: 'host',
                  joinStatus: 'approved',
                ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const KeoChatScreen(keoId: 'k1'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('keo_chat_subtitle')), findsOneWidget);
      expect(find.text('Kèo demo tối nay'), findsOneWidget);
      // Tên người gửi hiện trên bubble của người khác (uid mình = null trong
      // test vì Supabase chưa init → mọi bubble đều "người khác").
      expect(find.text('QA Linh Ballad'), findsOneWidget);
      expect(find.text('Toi nay hat nhe'), findsOneWidget);
    },
  );
}
