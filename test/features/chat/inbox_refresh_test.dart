import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/application/inbox_providers.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import 'package:cung_hat/features/chat/presentation/inbox_screen.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';

/// [DEBT] Keo-de-lam-moi cho inbox — man "cho tin" nhieu nhat ma truoc day
/// chi lam moi duoc bang cach doi tab qua lai.
void main() {
  testWidgets('keo xuong tren inbox -> fetch lai danh sach', (tester) async {
    var inboxCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inboxProvider.overrideWith((ref) async {
            inboxCalls++;
            return [
              MatchSummary(
                matchId: 'm1',
                otherId: 'u2',
                otherName: 'Linh',
                unread: 0,
              ),
            ];
          }),
          myKeosProvider.overrideWith((ref) async => const <Keo>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: InboxScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(inboxCalls, 1);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(inboxCalls, 2);
  });
}
