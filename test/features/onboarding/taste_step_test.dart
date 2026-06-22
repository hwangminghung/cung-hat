import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/onboarding/domain/music_ref.dart';
import 'package:cung_hat/features/onboarding/presentation/taste_step.dart';

void main() {
  testWidgets('tapping a genre chip toggles selection', (tester) async {
    final selected = <String>{};
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TasteChips(
      items: const [Genre(id: 'vpop', nameVi: 'V-Pop', nameEn: 'V-Pop')],
      labelOf: (g) => (g as Genre).nameVi,
      idOf: (g) => (g as Genre).id,
      selected: selected,
      onToggle: (id) => selected.contains(id) ? selected.remove(id) : selected.add(id),
    ))));
    await tester.tap(find.text('V-Pop'));
    await tester.pump();
    expect(selected.contains('vpop'), isTrue);
  });
}
