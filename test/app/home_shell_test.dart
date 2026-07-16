import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:cung_hat/app/home_shell.dart';
import 'package:cung_hat/features/chat/application/inbox_providers.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import 'package:cung_hat/features/chat/presentation/inbox_screen.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:cung_hat/features/profile/domain/profile_completion.dart';
import 'package:cung_hat/shared/widgets/stamp_chip.dart';
import 'package:cung_hat/shared/widgets/wave_progress.dart';

class _FakeLocationService extends Mock implements LocationService {}

void main() {
  testWidgets('HomeShell shows 4 tabs and switches', (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => LocationCaptureStatus.success);
    await tester.pumpWidget(
      ProviderScope(
        // Tab 0 now hosts DoiDeckScreen, which reads candidatesProvider →
        // Supabase. Override it with an empty list so the deck renders its
        // empty state instead of crashing (Supabase isn't initialized in tests).
        // Its initState also reads locationServiceProvider → Supabase; override
        // with a fake that returns false so initState never touches Supabase and
        // never invalidates the empty-deck override.
        overrides: [
          candidatesProvider(null)
              .overrideWith((ref) => Future.value(<Candidate>[])),
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
    expect(find.text('Chưa có kèo quanh đây'), findsOneWidget);
  });

  testWidgets('chọn tab Chat → inboxProvider refetch (kể cả lần quay lại)',
      (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => LocationCaptureStatus.success);
    // inboxProvider là FutureProvider one-shot (KHÔNG autoDispose): không
    // invalidate khi chuyển tab thì lần quay lại Chat dùng cache cũ — pill
    // 'Đến lượt bạn'/badge unread trễ. Đếm số lần build để chứng minh refetch.
    var inboxCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          candidatesProvider(null)
              .overrideWith((ref) => Future.value(<Candidate>[])),
          locationServiceProvider.overrideWithValue(fakeLoc),
          openKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
          inboxProvider.overrideWith((ref) {
            inboxCalls++;
            return Future.value(<MatchSummary>[]);
          }),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
    // Provider lazy: chưa vào tab Chat thì chưa build lần nào.
    expect(inboxCalls, 0);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(inboxCalls, 1);

    await tester.tap(find.text('Đôi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    // Không invalidate → provider giữ cache, vẫn 1. Có fix → refetch = 2.
    expect(inboxCalls, 2);
  });

  // [L10N] Smoke song ngữ: pump VỚI delegates + locale EN → UI chrome phải
  // hiện tiếng Anh (không rơi về fallback VI). Test khác pump KHÔNG delegates
  // để giữ nguyên finder tiếng Việt qua fallback — đây là test duy nhất
  // chứng minh nhánh EN thật sự sống.
  testWidgets('locale EN → tab labels hiện tiếng Anh', (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => LocationCaptureStatus.success);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          candidatesProvider(null)
              .overrideWith((ref) => Future.value(<Candidate>[])),
          locationServiceProvider.overrideWithValue(fakeLoc),
          openKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsNothing);
  });

  testWidgets('tab đã thăm giữ state khi chuyển đi (IndexedStack, audit M7)',
      (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => LocationCaptureStatus.success);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          candidatesProvider(null)
              .overrideWith((ref) => Future.value(<Candidate>[])),
          locationServiceProvider.overrideWithValue(fakeLoc),
          openKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
          inboxProvider.overrideWith((ref) => Future.value(<MatchSummary>[])),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đôi'));
    await tester.pumpAndSettle();

    // Trước fix: switch remount → InboxScreen bị dispose khi rời tab (mất
    // scroll/state). IndexedStack giữ tab đã thăm sống offstage.
    expect(find.byType(InboxScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      "tab Hồ sơ: dòng 'Ai đã thích bạn' có badge PRO (tránh bait-click)",
      (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => LocationCaptureStatus.success);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          candidatesProvider(null)
              .overrideWith((ref) => Future.value(<Candidate>[])),
          locationServiceProvider.overrideWithValue(fakeLoc),
          openKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
          myProfileProvider.overrideWith((ref) => Future.value(null)),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(StampChip, 'PRO'), findsOneWidget);
  });

  testWidgets('tab Hồ sơ: có WaveProgress (thẻ hoàn thiện) + nút bánh răng',
      (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => LocationCaptureStatus.success);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          candidatesProvider(null)
              .overrideWith((ref) => Future.value(<Candidate>[])),
          locationServiceProvider.overrideWithValue(fakeLoc),
          openKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
          // _CompletionCard chỉ render khi profile + taste non-null và
          // percent < 100 → hồ sơ trống (0%) cho WaveProgress xuất hiện.
          myProfileProvider
              .overrideWith((ref) => Future.value(const Profile(id: 'u1'))),
          myTasteCountsProvider
              .overrideWith((ref) => Future.value(const TasteCounts(0, 0, 0))),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.byType(WaveProgress), findsOneWidget);
    expect(find.byKey(const Key('profile_gear_btn')), findsOneWidget);
  });
}
