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
}
