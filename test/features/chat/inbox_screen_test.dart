import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/application/inbox_providers.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import 'package:cung_hat/features/chat/presentation/inbox_screen.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/wave_divider.dart';

void main() {
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
