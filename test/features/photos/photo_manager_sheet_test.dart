import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cung_hat/core/providers/supabase_providers.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/presentation/photo_manager_sheet.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';

import '../../support/supabase_mocks.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoTrue extends Mock implements GoTrueClient {}

class _FakeUser extends Fake implements User {
  @override
  final String id;
  _FakeUser(this.id);
}

/// A [SupabaseClient] whose `auth.currentUser?.id` returns [uid] so the sheet
/// can resolve the current user id without a live Supabase session.
SupabaseClient _clientWithUser(String uid) {
  final client = MockSupabaseClient();
  final auth = _MockGoTrue();
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(_FakeUser(uid));
  return client;
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required bool photosConsent,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(_clientWithUser('me')),
        myConsentsProvider.overrideWith(
          (ref) async => {'photos': photosConsent},
        ),
        myPhotoPathsProvider.overrideWithValue(const []),
        signedUrlsProvider('me').overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PhotoManagerSheet(
            // Deterministic picker: never touches a real gallery.
            pickBytes: () async => Uint8List.fromList([1, 2, 3]),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('consent chưa granted → hiện CTA cài đặt, không hiện slot', (
    tester,
  ) async {
    await _pumpSheet(tester, photosConsent: false);

    expect(find.byKey(const Key('photos_consent_cta')), findsOneWidget);
    expect(find.byKey(const Key('photo_slot_0')), findsNothing);
    expect(find.byKey(const Key('photo_slot_1')), findsNothing);
    expect(find.byKey(const Key('photo_slot_2')), findsNothing);
  });

  testWidgets('consent granted → hiện 6 slot, không hiện CTA', (tester) async {
    await _pumpSheet(tester, photosConsent: true);

    expect(find.byKey(const Key('photo_slot_0')), findsOneWidget);
    expect(find.byKey(const Key('photo_slot_1')), findsOneWidget);
    expect(find.byKey(const Key('photo_slot_2')), findsOneWidget);
    expect(find.byKey(const Key('photo_slot_3')), findsOneWidget);
    expect(find.byKey(const Key('photo_slot_4')), findsOneWidget);
    expect(find.byKey(const Key('photo_slot_5')), findsOneWidget);
    expect(find.byKey(const Key('photos_consent_cta')), findsNothing);
  });
}
