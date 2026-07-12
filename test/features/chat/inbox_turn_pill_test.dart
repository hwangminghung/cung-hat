import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/application/inbox_providers.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import 'package:cung_hat/features/chat/presentation/inbox_screen.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

void main() {
  Widget host({
    required MatchSummary match,
  }) {
    return ProviderScope(
      overrides: [
        inboxProvider.overrideWith((ref) async => [match]),
        myProfileProvider.overrideWith(
          (ref) => Future.value(const Profile(id: 'me')),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: InboxScreen()),
      ),
    );
  }

  testWidgets(
    'brand-new match with no messages shows "Nhắn trước đi" pill',
    (tester) async {
      await tester.pumpWidget(host(
        match: MatchSummary(
          matchId: 't1',
          otherId: 'other-id',
          otherName: 'Linh',
          unread: 0,
          lastSenderId: null,
        ),
      ));
      await tester.pump();

      expect(find.text('Nhắn trước đi'), findsOneWidget);
      expect(find.text('Đến lượt bạn'), findsNothing);
      expect(find.text('Sẵn sàng rủ đi hát'), findsNothing);
    },
  );

  testWidgets(
    'last message from the other person shows "Đến lượt bạn" pill',
    (tester) async {
      await tester.pumpWidget(host(
        match: MatchSummary(
          matchId: 't2',
          otherId: 'other-id',
          otherName: 'Linh',
          unread: 1,
          lastSenderId: 'other-id',
        ),
      ));
      await tester.pump();

      expect(find.text('Đến lượt bạn'), findsOneWidget);
      expect(find.text('Nhắn trước đi'), findsNothing);
      expect(find.text('Sẵn sàng rủ đi hát'), findsNothing);
    },
  );

  testWidgets(
    'last message from me shows the default subtitle and no pill',
    (tester) async {
      await tester.pumpWidget(host(
        match: MatchSummary(
          matchId: 't3',
          otherId: 'other-id',
          otherName: 'Linh',
          unread: 0,
          lastSenderId: 'me',
        ),
      ));
      await tester.pump();

      expect(find.text('Sẵn sàng rủ đi hát'), findsOneWidget);
      expect(find.text('Đến lượt bạn'), findsNothing);
      expect(find.text('Nhắn trước đi'), findsNothing);
      expect(find.byKey(const Key('turn_pill')), findsNothing);
    },
  );

  testWidgets(
    'inbox hiện tiêu đề section Tin nhắn đôi khi có match',
    (tester) async {
      await tester.pumpWidget(host(
        match: MatchSummary(
          matchId: 't4',
          otherId: 'other-id',
          otherName: 'Linh',
          unread: 0,
          lastSenderId: 'me',
        ),
      ));
      await tester.pump();

      expect(find.text('Tin nhắn đôi'), findsOneWidget);
    },
  );
}
