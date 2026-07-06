import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/data/profile_repository.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:cung_hat/features/profile/presentation/prompt_editor_sheet.dart';

import '../../support/supabase_mocks.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  test('setMyPrompts passes the list through as p_prompts', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('set_my_prompts', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk(null));
    final repo = ProfileRepository(client);

    final prompts = [
      {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
      {'prompt_id': 'p2', 'answer': 'Ballad'},
    ];
    await repo.setMyPrompts(prompts);

    verify(
      () => client.rpc(
        'set_my_prompts',
        params: {'p_prompts': prompts},
      ),
    ).called(1);
  });

  group('PromptEditorSheet', () {
    Widget host({
      required ProfileRepository repo,
      List<Map<String, dynamic>> existingPrompts = const [],
    }) {
      return ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repo),
          myProfileProvider.overrideWith(
            (ref) => Future.value(
              Profile(
                id: 'me',
                ageVerified: true,
                prompts: existingPrompts,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PromptEditorSheet()),
        ),
      );
    }

    testWidgets('shows the existing 2 answers from myProfileProvider', (
      tester,
    ) async {
      final repo = _MockProfileRepository();
      await tester.pumpWidget(
        host(
          repo: repo,
          existingPrompts: const [
            {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
            {'prompt_id': 'p2', 'answer': 'Ballad'},
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Em cua ngay hom qua'), findsOneWidget);
      expect(find.text('Ballad'), findsOneWidget);
    });

    testWidgets(
      'filling a 3rd answer then Save calls setMyPrompts with 3 entries',
      (tester) async {
        final repo = _MockProfileRepository();
        when(() => repo.setMyPrompts(any())).thenAnswer((_) async {});
        await tester.pumpWidget(
          host(
            repo: repo,
            existingPrompts: const [
              {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
              {'prompt_id': 'p2', 'answer': 'Ballad'},
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Expand the 3rd prompt row and type an answer.
        await tester.tap(find.byKey(const Key('prompt_row_p3')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('answer_field_p3')),
          'Vui la chinh',
        );
        await tester.pumpAndSettle();

        // Save sits below the fold once the sheet's 6 rows + an expanded
        // field push past the test viewport — the sheet is a
        // SingleChildScrollView, so scroll it into view before tapping.
        await tester.ensureVisible(find.byKey(const Key('save_prompts_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('save_prompts_btn')));
        await tester.pumpAndSettle();

        final captured = verify(() => repo.setMyPrompts(captureAny()))
            .captured
            .single as List<Map<String, String>>;
        expect(captured.length, 3);
        expect(captured[0], {
          'prompt_id': 'p1',
          'answer': 'Em cua ngay hom qua',
        });
        expect(captured[1], {'prompt_id': 'p2', 'answer': 'Ballad'});
        expect(captured[2], {'prompt_id': 'p3', 'answer': 'Vui la chinh'});
      },
    );

    testWidgets('selecting a 4th prompt shows the max-3 SnackBar', (
      tester,
    ) async {
      final repo = _MockProfileRepository();
      await tester.pumpWidget(
        host(
          repo: repo,
          existingPrompts: const [
            {'prompt_id': 'p1', 'answer': 'a'},
            {'prompt_id': 'p2', 'answer': 'b'},
            {'prompt_id': 'p3', 'answer': 'c'},
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('prompt_row_p4')));
      await tester.pumpAndSettle();

      expect(find.text('Tối đa 3 thẻ'), findsOneWidget);
      expect(find.byKey(const Key('answer_field_p4')), findsNothing);
    });

    testWidgets('repository error on save shows a SnackBar, does not crash', (
      tester,
    ) async {
      final repo = _MockProfileRepository();
      when(() => repo.setMyPrompts(any())).thenThrow(Exception('boom'));
      await tester.pumpWidget(
        host(
          repo: repo,
          existingPrompts: const [
            {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_prompts_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Không lưu được, thử lại.'), findsOneWidget);
    });

    testWidgets(
      'clearing while the field is expanded (controller already live) does '
      'not leave stale text on re-expand',
      (tester) async {
        final repo = _MockProfileRepository();
        await tester.pumpWidget(
          host(
            repo: repo,
            existingPrompts: const [
              {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Expand p1 first, so its TextEditingController is actually created
        // (it's lazily built on first field render) and holds the answer.
        await tester.tap(find.byKey(const Key('prompt_row_p1')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('answer_field_p1')))
              .controller!
              .text,
          'Em cua ngay hom qua',
        );

        // Clear (the button is visible alongside the live field) while still
        // expanded — this is the scenario where the controller must be
        // resynced, since it already exists and holds the old text.
        await tester.tap(find.byKey(const Key('clear_prompt_p1')));
        await tester.pumpAndSettle();
        expect(find.text('Em cua ngay hom qua'), findsNothing);

        // Re-expand and confirm the field is empty, not the stale answer.
        await tester.tap(find.byKey(const Key('prompt_row_p1')));
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(
          find.byKey(const Key('answer_field_p1')),
        );
        expect(field.controller!.text, '');
      },
    );

    testWidgets(
      'race: rows and Save are inert while the profile is loading; after it '
      'resolves the one-time seed never clobbers later edits',
      (tester) async {
        final repo = _MockProfileRepository();
        // Completer-backed override: the profile future resolves only when
        // this test says so, keeping the sheet in its loading window.
        final completer = Completer<Profile?>();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileRepositoryProvider.overrideWithValue(repo),
              myProfileProvider.overrideWith((ref) => completer.future),
            ],
            child: const MaterialApp(
              home: Scaffold(body: PromptEditorSheet()),
            ),
          ),
        );
        await tester.pump();

        // BEFORE the profile resolves: tapping a row must be a no-op (no
        // field opens — otherwise text typed now would collide with the
        // first seed) and Save must be disabled (saving now would ship the
        // unseeded empty set and wipe the server rows).
        await tester.tap(find.byKey(const Key('prompt_row_p1')));
        await tester.pump();
        expect(find.byKey(const Key('answer_field_p1')), findsNothing);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('save_prompts_btn')))
              .onPressed,
          isNull,
        );

        // Profile resolves with an existing p1 answer → seeded exactly once.
        completer.complete(
          const Profile(
            id: 'me',
            ageVerified: true,
            prompts: [
              {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Em cua ngay hom qua'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('save_prompts_btn')))
              .onPressed,
          isNotNull,
        );

        // AFTER seeding: edit p1, then trigger more rebuilds (collapse) —
        // the seed must never run again and overwrite the edit.
        await tester.tap(find.text('Bài mình luôn giành mic là…'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('answer_field_p1')),
          'Bai moi',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bài mình luôn giành mic là…')); // collapse
        await tester.pumpAndSettle();

        expect(find.text('Bai moi'), findsOneWidget);
        expect(find.text('Em cua ngay hom qua'), findsNothing);
      },
    );
  });
}
