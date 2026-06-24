import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/app/home_shell.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';

class _FakeLocationService extends Mock implements LocationService {}

void main() {
  testWidgets('HomeShell shows 4 tabs and switches', (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => false);
    await tester.pumpWidget(
      ProviderScope(
        // Tab 0 now hosts DoiDeckScreen, which reads candidatesProvider →
        // Supabase. Override it with an empty list so the deck renders its
        // empty state instead of crashing (Supabase isn't initialized in tests).
        // Its initState also reads locationServiceProvider → Supabase; override
        // with a fake that returns false so initState never touches Supabase and
        // never invalidates the empty-deck override.
        overrides: [
          candidatesProvider.overrideWith((ref) => Future.value(<Candidate>[])),
          locationServiceProvider.overrideWithValue(fakeLoc),
          openKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
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
    // Tab 1 now hosts KeoBoardScreen. With an empty openKeos override it shows
    // the empty-state text and the always-present "Tạo kèo" FAB.
    expect(find.text('Tạo kèo'), findsOneWidget);
    expect(find.text('Chưa có kèo nào quanh đây'), findsOneWidget);
  });
}
