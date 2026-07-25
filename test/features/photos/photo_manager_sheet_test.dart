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
  List<String> paths = const [],
  Future<List<String>> Function()? signedUrls,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(_clientWithUser('me')),
        myConsentsProvider.overrideWith(
          (ref) async => {'photos': photosConsent},
        ),
        myPhotoPathsProvider.overrideWithValue(paths),
        signedUrlsProvider(
          'me',
        ).overrideWith((ref) => (signedUrls ?? () async => const [])()),
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

  // [AUDIT] signedUrlsOf nuot moi loi sign-photo va tra [] (co y — deck rot ve
  // monogram). Nhung trong sheet quan ly anh, "co path ma khong co URL" tung
  // hien 6 o be trong tron voi nut × va khong mot loi giai thich nao — user
  // vua up 6 anh xong tuong app mat anh. Sheet phai noi that va cho thu lai.
  testWidgets('co path nhung khong ky duoc URL -> bao loi + thu lai duoc', (
    tester,
  ) async {
    var fetches = 0;
    await _pumpSheet(
      tester,
      photosConsent: true,
      paths: const ['me/1.jpg', 'me/2.jpg'],
      signedUrls: () async {
        fetches++;
        return const [];
      },
    );

    // Bao loi ro rang + tung o "co anh" hien trang thai vo, khong phai o trong.
    expect(find.byKey(const Key('photo_urls_error')), findsOneWidget);
    expect(find.byKey(const Key('photo_slot_broken_0')), findsOneWidget);
    expect(find.byKey(const Key('photo_slot_broken_1')), findsOneWidget);
    // O trong (slot 2+) van la o "+ them anh", khong dinh trang thai vo.
    expect(find.byKey(const Key('photo_slot_broken_2')), findsNothing);

    // Thu lai = mint lai URL da ky.
    expect(fetches, 1);
    await tester.tap(find.byKey(const Key('photo_urls_retry')));
    await tester.pumpAndSettle();
    expect(fetches, 2);
  });

  testWidgets('ky URL thanh cong -> khong hien bao loi', (tester) async {
    await _pumpSheet(
      tester,
      photosConsent: true,
      paths: const ['me/1.jpg'],
      // URL bat ky — Image.network se loi trong test nhung day la loi tai
      // ANH, khong phai loi ky URL, nen khong duoc hien photo_urls_error.
      signedUrls: () async => const ['http://localhost/1.jpg'],
    );

    expect(find.byKey(const Key('photo_urls_error')), findsNothing);
    expect(find.byKey(const Key('photo_slot_broken_0')), findsNothing);
    // Test HttpClient tra 400 cho moi anh mang — nuot dung MOT loi tai anh do,
    // khong lien quan den dieu test nay khoa.
    tester.takeException();
  });
}
