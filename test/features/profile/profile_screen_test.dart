import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:cung_hat/features/profile/domain/profile_completion.dart';
import 'package:cung_hat/features/profile/presentation/profile_screen.dart';
import 'package:cung_hat/shared/widgets/stamp_chip.dart';

void main() {
  testWidgets('profile screen exposes the mockup-18 hierarchy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myProfileProvider.overrideWith(
            (ref) async => const Profile(id: 'u1', displayName: 'Minh'),
          ),
          myTasteCountsProvider.overrideWith(
            (ref) async => const TasteCounts(0, 0, 0),
          ),
          entitlementsProvider.overrideWith((ref) async => <String>{}),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_18_profile')), findsOneWidget);
    expect(find.byKey(const Key('profile_identity_card')), findsOneWidget);
    expect(find.byKey(const Key('completion_card')), findsOneWidget);
    expect(find.widgetWithText(StampChip, 'PRO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile screen renders at the iOS presentation target', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myProfileProvider.overrideWith(
            (ref) async => const Profile(id: 'u1', displayName: 'Minh'),
          ),
          myTasteCountsProvider.overrideWith(
            (ref) async => const TasteCounts(0, 0, 0),
          ),
          entitlementsProvider.overrideWith((ref) async => <String>{}),
        ],
        child: MaterialApp(
          theme: AppTheme.light().copyWith(platform: TargetPlatform.iOS),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_18_profile')), findsOneWidget);
    expect(find.byKey(const Key('profile_identity_card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
