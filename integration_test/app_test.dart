import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cung_hat/app/app.dart';
import 'package:cung_hat/core/providers/supabase_providers.dart';

// Local Supabase dev stack. Overridable via --dart-define so the SAME test runs
// on a host target (desktop/web-driver → 127.0.0.1) AND on an Android emulator
// (host is reachable as 10.0.2.2 → pass --dart-define=SUPABASE_URL=http://10.0.2.2:54321).
// These are local dev creds, not secrets.
const _localUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://127.0.0.1:54321',
);
const _localAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
);

// Configured test credentials in local GoTrue (see supabase/config.toml).
const _testPhoneRaw = '900000001'; // UI shows a "+84 " prefix.
const _testOtp = '123456';

/// Pumps repeatedly until [finder] matches or [timeout] elapses. We avoid a
/// bare pumpAndSettle() across the GoTrue network round-trips because async
/// auth + go_router redirects can leave the tree perpetually "dirty" or settle
/// before the network completes.
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(url: _localUrl, anonKey: _localAnonKey); // ignore: deprecated_member_use
  });

  setUp(() async {
    // Each run starts logged-out so the redirect to /auth is deterministic.
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  });

  Widget buildApp() => ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(Supabase.instance.client),
        ],
        child: const CungHatApp(),
      );

  testWidgets('Test 1: auth happy path → onboarding (real GoTrue OTP)',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Land on the phone/auth screen.
    final sendBtn = find.byKey(const Key('send_otp_btn'));
    expect(sendBtn, findsOneWidget, reason: 'Expected the phone/auth screen');

    // Enter phone and request OTP (real GoTrue call).
    await tester.enterText(find.byType(TextField).first, _testPhoneRaw);
    await tester.pump();
    await tester.tap(sendBtn);

    // Wait for the OTP screen to appear after the network round-trip.
    final verifyBtn = find.byKey(const Key('verify_otp_btn'));
    await _pumpUntilFound(tester, verifyBtn);
    expect(verifyBtn, findsOneWidget,
        reason: 'Expected the OTP screen after sending OTP');

    // Enter the configured test OTP and verify (real GoTrue call).
    await tester.enterText(find.byType(TextField).first, _testOtp);
    await tester.pump();
    await tester.tap(verifyBtn);

    // After verify, the signed-in user has no profile → router redirects to
    // /onboarding whose first step is the DOB picker.
    final dobBtn = find.byKey(const Key('pick_dob_btn'));
    await _pumpUntilFound(tester, dobBtn);
    expect(dobBtn, findsOneWidget,
        reason: 'Expected onboarding DOB step after auth (left auth area)');
    // Sanity: we are no longer on the auth screen.
    expect(find.byKey(const Key('send_otp_btn')), findsNothing);
    expect(find.byKey(const Key('verify_otp_btn')), findsNothing);
  });

  testWidgets(
    'Test 2 (STRETCH): pick a DOB >=18 in onboarding',
    (tester) async {
      // TODO: Navigating the Material showDatePicker dialog via WidgetTester is
      // fiddly (year/day grid taps are brittle). Left skipped so it never
      // blocks Test 1. Drive the date dialog here when revisiting.
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
    },
    skip: true,
  );
}
