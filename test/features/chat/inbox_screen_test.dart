import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/application/inbox_providers.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import 'package:cung_hat/features/chat/presentation/inbox_screen.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/stamp_chip.dart';
import 'package:cung_hat/shared/widgets/wave_divider.dart';

void main() {
  testWidgets(
    'section Kèo của bạn hiện kèo với chip x/y và Chủ kèo khi mình host',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxProvider.overrideWith((ref) async => <MatchSummary>[]),
            myKeosProvider.overrideWith(
              (ref) async => const [
                Keo(
                  id: 'k-mine',
                  title: 'Kèo demo tối nay',
                  areaLabel: 'Hoàn Kiếm, Hà Nội',
                  status: 'planning',
                  sizeTarget: 4,
                  slotsFilled: 2,
                  isMine: true,
                ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: InboxScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Kèo của bạn'), findsOneWidget);
      expect(find.text('Kèo demo tối nay'), findsOneWidget);
      expect(find.text('Đang lên kế hoạch · Hoàn Kiếm, Hà Nội'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.widgetWithText(StampChip, 'Chủ kèo'), findsOneWidget);
      // Có kèo → KHÔNG rơi vào EmptyState dù chưa có match nào.
      expect(find.byType(EmptyState), findsNothing);
    },
  );

  testWidgets(
    'member (không phải host) không thấy chip Chủ kèo; matches vẫn render đủ',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxProvider.overrideWith(
              (ref) async => [
                MatchSummary(
                  matchId: 'm1',
                  otherId: 'other-id',
                  otherName: 'Linh',
                  unread: 0,
                  lastSenderId: 'me',
                ),
              ],
            ),
            myProfileProvider.overrideWith(
              (ref) => Future.value(const Profile(id: 'me')),
            ),
            myKeosProvider.overrideWith(
              (ref) async => const [
                Keo(
                  id: 'k-joined',
                  title: 'Tối thứ 6 hát Ballad',
                  status: 'open',
                  sizeTarget: 3,
                  slotsFilled: 1,
                ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: InboxScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Kèo của bạn'), findsOneWidget);
      expect(find.widgetWithText(StampChip, 'Chủ kèo'), findsNothing);
      expect(find.text('Tin nhắn đôi'), findsOneWidget);
      expect(find.text('Linh'), findsOneWidget);
    },
  );

  testWidgets(
    'không có kèo → không hiện label Kèo của bạn',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxProvider.overrideWith(
              (ref) async => [
                MatchSummary(
                  matchId: 'm2',
                  otherId: 'other-id',
                  otherName: 'An',
                  unread: 0,
                  lastSenderId: 'me',
                ),
              ],
            ),
            myProfileProvider.overrideWith(
              (ref) => Future.value(const Profile(id: 'me')),
            ),
            myKeosProvider.overrideWith((ref) async => const <Keo>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: InboxScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Kèo của bạn'), findsNothing);
      expect(find.text('Tin nhắn đôi'), findsOneWidget);
    },
  );

  testWidgets(
    'InboxScreen uses the shared EmptyState when there are no chats',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxProvider.overrideWith((ref) async => <MatchSummary>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: InboxScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Chưa có cuộc trò chuyện nào'), findsOneWidget);
    },
  );

  testWidgets(
    'inbox hiện tiêu đề section Tin nhắn đôi khi có match',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxProvider.overrideWith(
              (ref) async => [
                MatchSummary(
                  matchId: 't4',
                  otherId: 'other-id',
                  otherName: 'Linh',
                  unread: 0,
                  lastSenderId: 'me',
                ),
              ],
            ),
            myProfileProvider.overrideWith(
              (ref) => Future.value(const Profile(id: 'me')),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: InboxScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tin nhắn đôi'), findsOneWidget);
    },
  );

  testWidgets(
    'inbox hiển thị WaveDivider giữa các hàng khi có nhiều match',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxProvider.overrideWith(
              (ref) async => [
                MatchSummary(
                  matchId: 't5',
                  otherId: 'other-id-1',
                  otherName: 'Linh',
                  unread: 1,
                  lastSenderId: 'other-id-1',
                ),
                MatchSummary(
                  matchId: 't6',
                  otherId: 'other-id-2',
                  otherName: 'An',
                  unread: 0,
                  lastSenderId: 'me',
                ),
              ],
            ),
            myProfileProvider.overrideWith(
              (ref) => Future.value(const Profile(id: 'me')),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: InboxScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(WaveDivider), findsWidgets);
    },
  );
}
