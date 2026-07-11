import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/onboarding/presentation/dob_step.dart';
import 'package:cung_hat/l10n/app_localizations.dart';

void main() {
  test('isAdult true for >=18', () {
    expect(isAdult(DateTime(2000, 1, 1), now: DateTime(2026, 6, 20)), isTrue);
  });
  test('isAdult false for <18', () {
    expect(isAdult(DateTime(2010, 1, 1), now: DateTime(2026, 6, 20)), isFalse);
  });
  test('isAdult false exactly one day before 18th birthday', () {
    expect(isAdult(DateTime(2008, 6, 21), now: DateTime(2026, 6, 20)), isFalse);
  });
  test('isAdult true exactly on 18th birthday', () {
    expect(isAdult(DateTime(2008, 6, 20), now: DateTime(2026, 6, 20)), isTrue);
  });

  testWidgets('DOB uses three tappable date boxes with the preserved key', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DobStep(dob: DateTime(2004, 9, 12), onPick: (_) {}),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('09'), findsOneWidget);
    expect(find.text('2004'), findsOneWidget);
    expect(find.text('Ngày'), findsOneWidget);
    expect(find.text('Tháng'), findsOneWidget);
    expect(find.text('Năm'), findsOneWidget);
    expect(find.text('Chọn ngày sinh'), findsNothing);

    await tester.tap(find.byKey(const Key('pick_dob_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
