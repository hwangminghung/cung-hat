import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/keo/domain/keo_match_suggestion.dart';
import 'package:cung_hat/features/keo/presentation/keo_match_sheet.dart';
import 'package:cung_hat/shared/widgets/gradient_button.dart';
import 'package:cung_hat/shared/widgets/stamp_chip.dart';
import 'package:cung_hat/shared/widgets/ticket_card.dart';
import 'package:cung_hat/shared/widgets/wave_divider.dart';

/// Expected hiển thị giờ local tính động theo TZ máy chạy test — hardcode
/// chuỗi sẽ flaky khi CI chạy ở timezone khác.
String expectedLocalWindow(String startIso, String endIso) {
  final start = DateTime.parse(startIso).toLocal();
  final end = DateTime.parse(endIso).toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  String time(DateTime v) => '${two(v.hour)}:${two(v.minute)}';
  String dateTime(DateTime v) =>
      '${v.year.toString().padLeft(4, '0')}-${two(v.month)}-${two(v.day)} ${time(v)}';
  final sameDate =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  if (sameDate) return '${time(start)} - ${time(end)}';
  return '${dateTime(start)} - ${dateTime(end)}';
}

void main() {
  testWidgets('existing keo sheet calls onJoin', (tester) async {
    var joined = false;
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'existing_keo',
      keoId: 'k1',
      title: 'V-Pop toi nay',
      areaLabel: 'Thủ Đức',
      distanceBand: '1-3',
      sizeTarget: 4,
      slotsFilled: 2,
      genres: ['vpop'],
      hostName: 'Mai',
      joinMode: 'open',
      reasonLabels: ['shared_genres', 'near_you'],
      timeWindowStart: '2026-06-30T12:00:00Z',
      timeWindowEnd: '2026-06-30T15:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeoMatchSheet(
            suggestions: const [suggestion],
            onJoin: (_) async => joined = true,
            onCreate: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Kèo hợp với bạn'), findsOneWidget);
    expect(find.text('V-Pop toi nay'), findsOneWidget);
    expect(
      find.text(
        expectedLocalWindow(
          suggestion.timeWindowStart!,
          suggestion.timeWindowEnd!,
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('UTC'), findsNothing);
    expect(find.text('Hợp gu nhạc'), findsOneWidget);
    expect(find.text('Gần bạn'), findsOneWidget);
    expect(find.text('Thủ Đức'), findsOneWidget);
    expect(find.text('Mai'), findsOneWidget);
    expect(find.byType(TicketCard), findsOneWidget);
    expect(find.byType(WaveDivider), findsOneWidget);
    expect(find.widgetWithText(StampChip, 'vpop'), findsOneWidget);
    expect(find.byKey(const Key('screen_12_keo_auto_match')), findsOneWidget);
    expect(find.byKey(const Key('keo_match_reason_grid')), findsOneWidget);
    expect(find.byKey(const Key('keo_match_join_btn')), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);

    await tester.tap(find.byKey(const Key('keo_match_join_btn')));
    await tester.pumpAndSettle();

    expect(joined, isTrue);
  });

  testWidgets('proposal sheet calls onCreate only after confirmation', (
    tester,
  ) async {
    var created = false;
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'new_keo_proposal',
      // The DB fallback title ships with proper diacritics (see
      // 20260629120000_auto_keo_matching.sql) — no display-side rewriting.
      title: 'Kèo gợi ý tối nay',
      sizeTarget: 4,
      slotsFilled: 1,
      genres: ['vpop'],
      joinMode: 'open',
      reasonLabels: ['evening_slot', 'open_join'],
      proposedStart: '2026-06-30T12:00:00Z',
      proposedEnd: '2026-06-30T15:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeoMatchSheet(
            suggestions: const [suggestion],
            onJoin: (_) async {},
            onCreate: (_) async => created = true,
          ),
        ),
      ),
    );

    expect(created, isFalse);
    expect(find.text('Đã tìm thấy nhóm phù hợp'), findsOneWidget);
    expect(find.text('Kèo gợi ý tối nay'), findsOneWidget);
    expect(
      find.text(
        expectedLocalWindow(suggestion.proposedStart!, suggestion.proposedEnd!),
      ),
      findsOneWidget,
    );
    expect(find.text('Giờ đẹp'), findsOneWidget);
    expect(find.text('Vào nhanh'), findsOneWidget);

    await tester.tap(find.byKey(const Key('keo_match_create_btn')));
    await tester.pumpAndSettle();

    expect(created, isTrue);
  });

  testWidgets('suggestion ticket maps join mode from suggestion data', (
    tester,
  ) async {
    for (final mode in const ['open', 'approval']) {
      final suggestion = KeoMatchSuggestion(
        suggestionType: 'existing_keo',
        title: 'Kèo kiểm tra chế độ',
        joinMode: mode,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: KeoMatchSheet(
              suggestions: [suggestion],
              onJoin: (_) async {},
              onCreate: (_) async {},
            ),
          ),
        ),
      );

      final expected = mode == 'open' ? 'Mở · vào là tham gia' : 'Cần duyệt';
      final other = mode == 'open' ? 'Cần duyệt' : 'Mở · vào là tham gia';
      final ticket = find.byType(TicketCard);

      expect(
        find.descendant(of: ticket, matching: find.text(expected)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ticket, matching: find.text(other)),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('suggestion ticket follows the Screen 12 metadata hierarchy', (
    tester,
  ) async {
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'existing_keo',
      title: 'Ballad tối nay',
      areaLabel: 'Music Box Thủ Đức',
      distanceBand: '1-3',
      sizeTarget: 5,
      slotsFilled: 3,
      genres: ['Ballad'],
      hostName: 'Chủ kèo Minh',
      joinMode: 'open',
      timeWindowStart: '2026-07-17T20:00:00',
      timeWindowEnd: '2026-07-17T22:00:00',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: KeoMatchSheet(
            suggestions: const [suggestion],
            onJoin: (_) async {},
            onCreate: (_) async {},
          ),
        ),
      ),
    );

    final ticket = find.byType(TicketCard);
    Finder ticketText(String value) =>
        find.descendant(of: ticket, matching: find.text(value));

    final time = ticketText(
      expectedLocalWindow(
        suggestion.timeWindowStart!,
        suggestion.timeWindowEnd!,
      ),
    );
    final title = ticketText(suggestion.title);
    final area = ticketText(suggestion.areaLabel!);
    final distance = ticketText('${suggestion.distanceBand} km');
    final capacity = ticketText('3/5 người');
    final genre = ticketText('Ballad');
    final joinMode = ticketText('Mở · vào là tham gia');
    final host = ticketText(suggestion.hostName!);

    expect(time, findsOneWidget);
    expect(title, findsOneWidget);
    expect(area, findsOneWidget);
    expect(distance, findsOneWidget);
    expect(capacity, findsOneWidget);
    expect(genre, findsOneWidget);
    expect(host, findsOneWidget);

    final timeY = tester.getTopLeft(time).dy;
    final titleY = tester.getTopLeft(title).dy;
    final areaY = tester.getTopLeft(area).dy;
    final distanceY = tester.getTopLeft(distance).dy;
    final capacityY = tester.getTopLeft(capacity).dy;
    final genreY = tester.getTopLeft(genre).dy;
    final hostY = tester.getTopLeft(host).dy;

    expect(timeY, lessThan(titleY));
    expect(titleY, lessThan(areaY));
    expect(areaY, lessThan(distanceY));
    expect(distanceY, lessThan(capacityY));
    expect(capacityY, lessThan(genreY));
    expect(genreY, lessThan(hostY));

    expect(joinMode, findsOneWidget);
    expect(tester.getTopLeft(joinMode).dy, lessThan(hostY));
  });

  testWidgets('empty suggestions show fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeoMatchSheet(
            suggestions: const [],
            onJoin: (_) async {},
            onCreate: (_) async {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('screen_12_keo_auto_match')), findsOneWidget);
    expect(
      find.text('Chưa tìm được kèo phù hợp. Thử lại sau.'),
      findsOneWidget,
    );
  });

  testWidgets('sheet body is scrollable for constrained layouts', (
    tester,
  ) async {
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'existing_keo',
      title: 'Keo co tieu de dai can hien thi trong khung nho',
      sizeTarget: 4,
      slotsFilled: 2,
      genres: ['vpop'],
      joinMode: 'open',
      reasonLabels: [
        'shared_genres',
        'near_you',
        'evening_slot',
        'open_join',
        'available_slots',
        'active_host',
        'ly_do_moi',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 260),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: KeoMatchSheet(
              suggestions: const [suggestion],
              onJoin: (_) async {},
              onCreate: (_) async {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('ly_do_moi'), findsOneWidget);
  });

  testWidgets('proposal actions stack safely at 320px with large text', (
    tester,
  ) async {
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'new_keo_proposal',
      title: 'Kèo gợi ý tối nay',
      reasonLabels: ['evening_slot', 'available_slots'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 260),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: KeoMatchSheet(
              suggestions: const [suggestion],
              onJoin: (_) async {},
              onCreate: (_) async {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('keo_match_later_btn')), findsOneWidget);
    expect(find.byKey(const Key('keo_match_create_btn')), findsOneWidget);
  });

  testWidgets('existing keo submit disables button and ignores repeat taps', (
    tester,
  ) async {
    final completer = Completer<void>();
    var joinCalls = 0;
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'existing_keo',
      keoId: 'k1',
      title: 'V-Pop toi nay',
      sizeTarget: 4,
      slotsFilled: 2,
      genres: ['vpop'],
      joinMode: 'open',
      reasonLabels: ['shared_genres'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeoMatchSheet(
            suggestions: const [suggestion],
            onJoin: (_) {
              joinCalls += 1;
              return completer.future;
            },
            onCreate: (_) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('keo_match_join_btn')));
    await tester.pump();

    expect(joinCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final joinButton = tester.widget<GradientButton>(
      find.byKey(const Key('keo_match_join_btn')),
    );
    expect(joinButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('keo_match_join_btn')));
    await tester.pump();
    expect(joinCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();

    final enabledJoinButton = tester.widget<GradientButton>(
      find.byKey(const Key('keo_match_join_btn')),
    );
    expect(enabledJoinButton.onPressed, isNotNull);
    expect(joinCalls, 1);
  });

  testWidgets('proposal submit disables buttons and ignores repeat taps', (
    tester,
  ) async {
    final completer = Completer<void>();
    var createCalls = 0;
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'new_keo_proposal',
      title: 'Keo goi y toi nay',
      sizeTarget: 4,
      slotsFilled: 1,
      genres: ['vpop'],
      joinMode: 'open',
      reasonLabels: ['evening_slot'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeoMatchSheet(
            suggestions: const [suggestion],
            onJoin: (_) async {},
            onCreate: (_) {
              createCalls += 1;
              return completer.future;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('keo_match_create_btn')));
    await tester.pump();

    expect(createCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final createButton = tester.widget<GradientButton>(
      find.byKey(const Key('keo_match_create_btn')),
    );
    final laterButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('keo_match_later_btn')),
    );
    expect(createButton.onPressed, isNull);
    expect(laterButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('keo_match_create_btn')));
    await tester.pump();
    expect(createCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();

    final enabledCreateButton = tester.widget<GradientButton>(
      find.byKey(const Key('keo_match_create_btn')),
    );
    final enabledLaterButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('keo_match_later_btn')),
    );
    expect(enabledCreateButton.onPressed, isNotNull);
    expect(enabledLaterButton.onPressed, isNotNull);
    expect(createCalls, 1);
  });

  testWidgets(
    'auto-match result stays responsive across required widths and text scales',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const suggestion = KeoMatchSuggestion(
        suggestionType: 'existing_keo',
        keoId: 'responsive',
        title: 'V-Pop tối nay cùng hội bạn',
        areaLabel: 'Music Box Thủ Đức',
        distanceBand: '1-3',
        sizeTarget: 5,
        slotsFilled: 3,
        genres: ['V-Pop', 'Ballad'],
        hostName: 'Minh',
        joinMode: 'open',
        reasonLabels: [
          'shared_genres',
          'near_you',
          'evening_slot',
          'available_slots',
        ],
        timeWindowStart: '2026-07-17T20:00:00',
        timeWindowEnd: '2026-07-17T22:00:00',
      );

      for (final width in const [360.0, 393.0, 430.0]) {
        for (final scale in const [1.0, 1.2, 1.4]) {
          await tester.binding.setSurfaceSize(Size(width, 844));
          final platform = width == 393 && scale == 1.4
              ? TargetPlatform.iOS
              : TargetPlatform.android;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light().copyWith(platform: platform),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 844),
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: Scaffold(
                  body: KeoMatchSheet(
                    suggestions: const [suggestion],
                    onJoin: (_) async {},
                    onCreate: (_) async {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: '${width}dp ×$scale on $platform',
          );
          expect(
            find.byKey(const Key('screen_12_keo_auto_match')),
            findsOneWidget,
          );
          expect(find.byType(TicketCard), findsOneWidget);
          expect(
            find.byKey(const Key('keo_match_reason_grid')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('keo_match_join_btn')), findsOneWidget);

          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}
