import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/chat/application/inbox_providers.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/app/home_shell.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile_completion.dart';
import 'package:cung_hat/features/profile/presentation/profile_screen.dart';

import '../support/presentation_harness.dart';

class _FakeLocationService extends Mock implements LocationService {}

/// Shell-level companion to the per-screen presentation matrix. It verifies
/// that all four lazily mounted tabs remain reachable without losing their
/// production screen anchors while width, text scale, and platform change.
void main() {
  final longKeo = Keo(
    id: 'k-long',
    title:
        'Kèo hát K-Pop cuối tuần cực kỳ dài để kiểm tra xuống dòng hai dòng (Hà Nội)',
    areaLabel: 'Quận Cầu Giấy, Hà Nội',
    distanceBand: '3-5',
    timeWindowStart: DateTime.now()
        .add(const Duration(hours: 5))
        .toIso8601String(),
    timeWindowEnd: DateTime.now()
        .add(const Duration(hours: 7))
        .toIso8601String(),
    sizeTarget: 5,
    slotsFilled: 2,
    genres: const ['kpop', 'vpop', 'ballad'],
    hostName: 'Cùng Hát Hà Nội',
    memberNames: const ['Minh', 'Trang'],
  );

  Future<void> pumpShell(
    WidgetTester tester, {
    required double width,
    required double textScale,
    required TargetPlatform platform,
  }) async {
    final fakeLoc = _FakeLocationService();
    when(
      () => fakeLoc.captureAndPush(),
    ).thenAnswer((_) async => LocationCaptureStatus.success);
    await pumpPresentation(
      tester,
      size: Size(width, 852),
      textScale: textScale,
      platform: platform,
      disableAnimations: true,
      child: ProviderScope(
        overrides: [
          candidatesProvider(
            null,
          ).overrideWith((ref) => Future.value(<Candidate>[])),
          locationServiceProvider.overrideWithValue(fakeLoc),
          openKeosProvider.overrideWith((ref) => Future.value([longKeo])),
          myKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
          inboxProvider.overrideWith((ref) => Future.value(<MatchSummary>[])),
          entitlementsProvider.overrideWith((ref) async => <String>{}),
          myProfileProvider.overrideWith((ref) => Future.value(null)),
          myTasteCountsProvider.overrideWith(
            (ref) => Future.value(const TasteCounts(0, 0, 0)),
          ),
        ],
        child: const HomeShell(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final platform in presentationPlatforms) {
    for (final width in presentationWidths) {
      for (final scale in presentationTextScales) {
        testWidgets(
          '4 tab anchors @ ${width.toInt()}dp ×$scale on ${platform.name}',
          (tester) async {
            await pumpShell(
              tester,
              width: width,
              textScale: scale,
              platform: platform,
            );

            expect(find.byKey(const Key('screen_07_doi_deck')), findsOneWidget);
            expect(tester.takeException(), isNull);

            await tester.tap(find.text('Kèo'));
            await tester.pumpAndSettle();
            expect(find.textContaining('Kèo hát K-Pop'), findsOneWidget);
            expect(
              find.byKey(const Key('screen_11_keo_board')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);

            await tester.tap(find.text('Tin nhắn'));
            await tester.pumpAndSettle();
            expect(find.text('Chưa có cuộc trò chuyện'), findsOneWidget);
            expect(find.byKey(const Key('screen_15_inbox')), findsOneWidget);
            expect(tester.takeException(), isNull);

            await tester.tap(find.text('Hồ sơ'));
            await tester.pumpAndSettle();
            expect(find.byType(ProfileScreen), findsOneWidget);
            expect(find.byKey(const Key('screen_18_profile')), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
