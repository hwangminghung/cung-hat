import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_spacing.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/shared/widgets/stamp_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

BoxDecoration _decoration(WidgetTester tester) {
  final containerFinder = find.descendant(
    of: find.byType(StampChip),
    matching: find.byType(Container),
  );
  expect(containerFinder, findsOneWidget);
  return tester.widget<Container>(containerFinder).decoration! as BoxDecoration;
}

void main() {
  testWidgets('StampChip renders a teal stamp with a leading icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const StampChip(
          label: 'Đang mở',
          tone: StampChipTone.teal,
          leadingIcon: Icons.music_note_rounded,
        ),
      ),
    );

    final decoration = _decoration(tester);
    final border = decoration.border! as Border;
    expect(decoration.color, AppColors.teal);
    expect(decoration.borderRadius, BorderRadius.circular(AppSpacing.xs));
    expect(border.top.color, AppColors.ink);
    expect(border.top.width, 2);

    final label = tester.widget<Text>(find.text('Đang mở'));
    expect(label.style?.color, AppColors.ink);
    expect(label.style?.fontWeight, FontWeight.w700);

    final icon = tester.widget<Icon>(find.byIcon(Icons.music_note_rounded));
    expect(icon.color, AppColors.ink);
    expect(icon.size, 16);
  });

  testWidgets('StampChip maps the lime tone without adding an icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const StampChip(label: 'Indie', tone: StampChipTone.lime)),
    );

    expect(_decoration(tester).color, AppColors.secondary);
    expect(
      find.descendant(of: find.byType(StampChip), matching: find.byType(Icon)),
      findsNothing,
    );
  });
}
