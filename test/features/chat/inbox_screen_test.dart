import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/application/inbox_providers.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import 'package:cung_hat/features/chat/presentation/inbox_screen.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';

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
}
