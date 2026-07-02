import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
