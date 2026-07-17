import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
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

class _FakeLocationService extends Mock implements LocationService {}

/// UI review 2026-07-16: smoke responsive — 4 tab render ở 360/393/412dp và
/// text scale 1.0/1.2 KHÔNG overflow (overflow trong widget test là
/// FlutterError → test fail), kèm kèo tiêu đề dài để ép clamp 2 dòng.
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

  Future<void> pumpShell(WidgetTester tester) async {
    final fakeLoc = _FakeLocationService();
    when(
      () => fakeLoc.captureAndPush(),
    ).thenAnswer((_) async => LocationCaptureStatus.success);
    await tester.pumpWidget(
      ProviderScope(
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
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 393.0, 412.0]) {
    for (final scale in [1.0, 1.2]) {
      testWidgets('4 tab không overflow @ ${width.toInt()}dp ×$scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearAllTestValues);

        await pumpShell(tester);
        // Đôi (tab 0 mặc định) — deck rỗng + header 4 nút.
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Kèo'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Kèo hát K-Pop'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Tin nhắn'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa có cuộc trò chuyện'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Hồ sơ'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
