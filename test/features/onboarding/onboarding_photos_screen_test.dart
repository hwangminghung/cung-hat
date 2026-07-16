import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cung_hat/core/providers/supabase_providers.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/onboarding/presentation/onboarding_photos_screen.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';

import '../../support/supabase_mocks.dart';

class _MockGoTrue extends Mock implements GoTrueClient {}

class _FakeUser extends Fake implements User {
  @override
  final String id;
  _FakeUser(this.id);
}

SupabaseClient _clientWithUser(String uid) {
  final client = MockSupabaseClient();
  final auth = _MockGoTrue();
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(_FakeUser(uid));
  return client;
}

Future<void> _pump(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/onboarding/photos',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('home-stub'))),
      ),
      GoRoute(
        path: '/onboarding/photos',
        builder: (_, _) => const OnboardingPhotosScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(_clientWithUser('me')),
        // photos là consent BẮT BUỘC ở bước 2 nên tới đây luôn granted.
        myConsentsProvider.overrideWith((ref) async => {'photos': true}),
        myPhotoPathsProvider.overrideWithValue(const []),
        signedUrlsProvider('me').overrideWith((ref) async => const []),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Picker thật không bao giờ bị đụng trong test: không tap slot nào.
  setUpAll(() => Uint8List(0));

  testWidgets('bước ảnh sau onboarding: grid ảnh + Xong + Để sau (P1-6)', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Thêm ảnh'), findsOneWidget);
    expect(find.byKey(const Key('photo_slot_0')), findsOneWidget);
    expect(find.byKey(const Key('onb_photos_done')), findsOneWidget);
    expect(find.byKey(const Key('onb_photos_skip')), findsOneWidget);
  });

  testWidgets('bấm Để sau → về home (bước ảnh skip được)', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('onb_photos_skip')));
    await tester.pumpAndSettle();

    expect(find.text('home-stub'), findsOneWidget);
  });

  testWidgets('bấm Xong → về home', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(find.byKey(const Key('onb_photos_done')));
    await tester.tap(find.byKey(const Key('onb_photos_done')));
    await tester.pumpAndSettle();

    expect(find.text('home-stub'), findsOneWidget);
  });
}
