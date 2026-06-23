import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/home_shell.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';

void main() {
  testWidgets('HomeShell shows 4 tabs and switches', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Tab 0 now hosts DoiDeckScreen, which reads candidatesProvider →
        // Supabase. Override it with an empty list so the deck renders its
        // empty state instead of crashing (Supabase isn't initialized in tests).
        overrides: [
          candidatesProvider.overrideWith((ref) => Future.value(<Candidate>[])),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đôi'), findsOneWidget);
    expect(find.text('Kèo'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
    await tester.tap(find.text('Kèo'));
    await tester.pumpAndSettle();
    expect(find.text('Kèo — sắp có'), findsOneWidget);
  });
}
