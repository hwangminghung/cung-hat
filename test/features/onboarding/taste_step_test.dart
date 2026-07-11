import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/features/onboarding/domain/music_ref.dart';
import 'package:cung_hat/features/onboarding/presentation/taste_step.dart';

void main() {
  testWidgets('tapping a genre chip toggles selection on', (tester) async {
    final selected = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TasteChips(
            items: const [Genre(id: 'vpop', nameVi: 'V-Pop', nameEn: 'V-Pop')],
            labelOf: (g) => g.nameVi,
            idOf: (g) => g.id,
            selected: selected,
            onToggle: (id) =>
                selected.contains(id) ? selected.remove(id) : selected.add(id),
          ),
        ),
      ),
    );
    await tester.tap(find.text('V-Pop'));
    await tester.pump();
    expect(selected.contains('vpop'), isTrue);
  });

  testWidgets('tapping a selected genre chip toggles selection off', (
    tester,
  ) async {
    final selected = <String>{'vpop'};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TasteChips(
            items: const [Genre(id: 'vpop', nameVi: 'V-Pop', nameEn: 'V-Pop')],
            labelOf: (g) => g.nameVi,
            idOf: (g) => g.id,
            selected: selected,
            onToggle: (id) =>
                selected.contains(id) ? selected.remove(id) : selected.add(id),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('chip_vpop')));
    await tester.pump();
    expect(selected.contains('vpop'), isFalse);
  });

  testWidgets('empty taste lists show a visible empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TasteChips<Genre>(
            items: const [],
            labelOf: (g) => g.nameVi,
            idOf: (g) => g.id,
            selected: const {},
            onToggle: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('taste_empty')), findsOneWidget);
  });

  testWidgets('selected and unselected items keep retro FilterChip styling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TasteChips(
            items: const [
              Genre(id: 'vpop', nameVi: 'V-Pop', nameEn: 'V-Pop'),
              Genre(id: 'rap', nameVi: 'Rap Việt', nameEn: 'Vietnamese Rap'),
            ],
            labelOf: (genre) => genre.nameVi,
            idOf: (genre) => genre.id,
            selected: const {'vpop'},
            onToggle: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(FilterChip), findsNWidgets(2));

    final selected = tester.widget<FilterChip>(
      find.byKey(const Key('chip_vpop')),
    );
    expect(selected.selected, isTrue);
    expect(selected.selectedColor, AppColors.ink);
    expect(selected.checkmarkColor, AppColors.secondary);
    expect(selected.showCheckmark, isTrue);
    expect(selected.side, const BorderSide(color: AppColors.ink, width: 2));

    final unselected = tester.widget<FilterChip>(
      find.byKey(const Key('chip_rap')),
    );
    expect(unselected.selected, isFalse);
    expect(unselected.backgroundColor, AppColors.surface);
    expect(unselected.side, const BorderSide(color: AppColors.ink, width: 2));
  });
}
