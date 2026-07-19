import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/domain/keo_member.dart';
import 'package:cung_hat/core/analytics/analytics_service.dart';
import 'package:cung_hat/features/keo/presentation/keo_chat_screen.dart';
import '../../support/analytics_fakes.dart';
import '../../support/supabase_mocks.dart';

class _MockChatRepo extends Mock implements ChatRepository {}

void main() {
  testWidgets(
    'chat nhóm keeps its rules, timeline, and composer above a compact keyboard',
    (tester) async {
      const viewport = Size(360, 640);
      const keyboardHeight = 260.0;
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _MockChatRepo();
      when(() => repo.markKeoRead('k1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(repo),
            keoMessageHistoryProvider(
              'k1',
            ).overrideWith((ref) async => const <Message>[]),
            keoLiveMessagesProvider(
              'k1',
            ).overrideWith((ref) => const Stream<Message>.empty()),
            keoHeaderProvider('k1').overrideWith(
              (ref) async => const Keo(
                id: 'k1',
                title: 'V-Pop tối nay',
                status: 'planning',
              ),
            ),
            keoRosterProvider('k1').overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: viewport,
                viewInsets: EdgeInsets.only(bottom: keyboardHeight),
              ),
              child: KeoChatScreen(keoId: 'k1'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final screen = find.byKey(const Key('screen_17_keo_group_chat'));
      final timeline = find.byKey(const Key('chat_timeline'));
      final composer = find.byKey(const Key('chat_composer'));
      expect(screen, findsOneWidget);
      expect(find.byKey(const Key('keo_chat_subtitle')), findsOneWidget);
      expect(find.byKey(const Key('group_rules_banner')), findsOneWidget);
      expect(timeline, findsOneWidget);
      expect(composer, findsOneWidget);

      final screenRect = tester.getRect(screen);
      final timelineRect = tester.getRect(timeline);
      final composerRect = tester.getRect(composer);
      expect(timelineRect.height, greaterThan(0));
      expect(timelineRect.bottom, composerRect.top);
      expect(
        composerRect.bottom,
        lessThanOrEqualTo(viewport.height - keyboardHeight),
      );
      expect(composerRect.bottom, screenRect.bottom);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'chat nhóm remains overflow-free at required widths and text scales',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _MockChatRepo();
      when(() => repo.markKeoRead('k1')).thenAnswer((_) async {});

      for (final width in const [360.0, 393.0, 430.0]) {
        for (final scale in const [1.0, 1.2, 1.4]) {
          await tester.binding.setSurfaceSize(Size(width, 800));
          final platform = width == 393 && scale == 1.4
              ? TargetPlatform.iOS
              : TargetPlatform.android;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                chatRepositoryProvider.overrideWithValue(repo),
                keoMessageHistoryProvider(
                  'k1',
                ).overrideWith((ref) async => const <Message>[]),
                keoLiveMessagesProvider(
                  'k1',
                ).overrideWith((ref) => const Stream<Message>.empty()),
                keoHeaderProvider('k1').overrideWith(
                  (ref) async => const Keo(
                    id: 'k1',
                    title: 'Kèo V-Pop tối nay với tiêu đề rất dài',
                    status: 'planning',
                  ),
                ),
                keoRosterProvider('k1').overrideWith((ref) async => const []),
              ],
              child: MaterialApp(
                theme: AppTheme.light().copyWith(platform: platform),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 800),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const KeoChatScreen(keoId: 'k1'),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(
            find.byKey(const Key('screen_17_keo_group_chat')),
            findsOneWidget,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow at ${width.toInt()}dp ×$scale on $platform',
          );
        }
      }
    },
  );

  testWidgets(
    'gửi tin nhóm thành công → log chat_sent thread_type=keo (P0-3)',
    (tester) async {
      final repo = _MockChatRepo();
      final analytics = RecordingAnalytics();
      when(() => repo.markKeoRead('k1')).thenAnswer((_) async {});
      when(
        () => repo.sendKeoMessage(any(), any()),
      ).thenAnswer((_) async => 'm1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(repo),
            analyticsProvider.overrideWithValue(analytics),
            keoMessageHistoryProvider(
              'k1',
            ).overrideWith((ref) async => const <Message>[]),
            keoLiveMessagesProvider(
              'k1',
            ).overrideWith((ref) => const Stream<Message>.empty()),
            keoHeaderProvider('k1').overrideWith((ref) async => null),
            keoRosterProvider('k1').overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const KeoChatScreen(keoId: 'k1'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'tối nay hát nhé');
      await tester.tap(find.byKey(const Key('send_btn')));
      await tester.pump();

      expect(analytics.events, ['chat_sent']);
      expect(analytics.params.single, {'thread_type': 'keo'});
    },
  );
  test('sendKeoMessage calls send_keo_message RPC', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('send_keo_message', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk('m1'));
    final id = await ChatRepository(client).sendKeoMessage('k1', 'hi nhóm');
    expect(id, 'm1');
    verify(
      () => client.rpc(
        'send_keo_message',
        params: {'p_keo': 'k1', 'p_body': 'hi nhóm'},
      ),
    ).called(1);
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
            keoLiveMessagesProvider(
              'k1',
            ).overrideWith((ref) => const Stream<Message>.empty()),
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
      expect(
        tester.widget<Text>(find.text('QA Linh Ballad')).style?.color,
        AppColors.ink,
      );
      expect(find.text('Toi nay hat nhe'), findsOneWidget);
    },
  );

  testWidgets('chat nhóm chèn divider ngày + giờ HH:mm trên bubble', (
    tester,
  ) async {
    final repo = _MockChatRepo();
    when(() => repo.markKeoRead('k1')).thenAnswer((_) async {});
    // 2 tin khác ngày, đều quá khứ (né nhãn 'Hôm nay' phụ thuộc ngày chạy);
    // giờ khác nhau để find.text từng HH:mm là duy nhất.
    const isoA = '2026-07-05T10:00:00Z';
    const isoB = '2026-07-06T11:30:00Z';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repo),
          keoMessageHistoryProvider('k1').overrideWith(
            (ref) async => const [
              Message(
                id: 'm1',
                threadId: 'k1',
                senderId: 'linh-id',
                body: 'hom qua',
                createdAt: isoA,
              ),
              Message(
                id: 'm2',
                threadId: 'k1',
                senderId: 'linh-id',
                body: 'hom nay',
                createdAt: isoB,
              ),
            ],
          ),
          keoLiveMessagesProvider(
            'k1',
          ).overrideWith((ref) => const Stream<Message>.empty()),
          keoHeaderProvider('k1').overrideWith((ref) async => null),
          keoRosterProvider('k1').overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const KeoChatScreen(keoId: 'k1'),
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
