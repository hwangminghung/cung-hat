import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/features/keo/domain/keo_match_suggestion.dart';
import 'package:cung_hat/features/keo/presentation/keo_match_sheet.dart';

void main() {
  testWidgets('existing keo sheet calls onJoin', (tester) async {
    var joined = false;
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'existing_keo',
      keoId: 'k1',
      title: 'V-Pop toi nay',
      distanceBand: '1-3',
      sizeTarget: 4,
      slotsFilled: 2,
      genres: ['vpop'],
      hostName: 'Mai',
      joinMode: 'open',
      reasonLabels: ['shared_genres', 'near_you'],
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

    expect(find.text('Keo hop voi ban'), findsOneWidget);
    expect(find.text('V-Pop toi nay'), findsOneWidget);
    expect(find.text('Hop gu nhac'), findsOneWidget);
    expect(find.text('Gan ban'), findsOneWidget);

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
      title: 'Keo goi y toi nay',
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
    expect(find.text('Tao keo moi tu goi y nay?'), findsOneWidget);
    expect(find.text('Keo goi y toi nay'), findsOneWidget);
    expect(find.text('Gio dep'), findsOneWidget);
    expect(find.text('Vao nhanh'), findsOneWidget);

    await tester.tap(find.byKey(const Key('keo_match_create_btn')));
    await tester.pumpAndSettle();

    expect(created, isTrue);
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

    expect(
      find.text('Chua tim duoc keo phu hop. Thu lai sau.'),
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
    final joinButton = tester.widget<FilledButton>(
      find.byKey(const Key('keo_match_join_btn')),
    );
    expect(joinButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('keo_match_join_btn')));
    await tester.pump();
    expect(joinCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();

    final enabledJoinButton = tester.widget<FilledButton>(
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
    final createButton = tester.widget<FilledButton>(
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

    final enabledCreateButton = tester.widget<FilledButton>(
      find.byKey(const Key('keo_match_create_btn')),
    );
    final enabledLaterButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('keo_match_later_btn')),
    );
    expect(enabledCreateButton.onPressed, isNotNull);
    expect(enabledLaterButton.onPressed, isNotNull);
    expect(createCalls, 1);
  });
}
