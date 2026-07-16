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

  Future<void> pumpStep(
    WidgetTester tester, {
    DateTime? dob,
    ValueChanged<DateTime>? onPick,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DobStep(dob: dob, onPick: onPick ?? (_) {}),
          ),
        ),
      ),
    );
  }

  testWidgets('P2-a: 3 ô NHẬP trực tiếp thay modal picker, giữ key cũ', (
    tester,
  ) async {
    await pumpStep(tester, dob: DateTime(2004, 9, 12));

    // Giá trị dob có sẵn hiển thị trong 3 ô nhập.
    expect(
      tester.widget<TextField>(find.byKey(const Key('dob_day'))).controller?.text,
      '12',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('dob_month')))
          .controller
          ?.text,
      '09',
    );
    expect(
      tester.widget<TextField>(find.byKey(const Key('dob_year'))).controller?.text,
      '2004',
    );
    expect(find.text('Ngày'), findsOneWidget);
    expect(find.text('Tháng'), findsOneWidget);
    expect(find.text('Năm'), findsOneWidget);
    // Key cũ giữ nguyên làm mỏ neo cho integration_test/app_test.dart.
    expect(find.byKey(const Key('pick_dob_btn')), findsOneWidget);

    // Tap vào ô KHÔNG mở modal picker nữa (lý do P2-a: picker brittle).
    await tester.tap(find.byKey(const Key('dob_day')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('P2-a: nhập đủ 3 ô hợp lệ → onPick nhận đúng ngày', (
    tester,
  ) async {
    DateTime? picked;
    await pumpStep(tester, onPick: (d) => picked = d);

    await tester.enterText(find.byKey(const Key('dob_day')), '01');
    await tester.enterText(find.byKey(const Key('dob_month')), '01');
    await tester.enterText(find.byKey(const Key('dob_year')), '2000');
    await tester.pump();

    expect(picked, DateTime(2000, 1, 1));
  });

  testWidgets('P2-a: ngày không tồn tại (31/02) → không onPick', (
    tester,
  ) async {
    DateTime? picked;
    await pumpStep(tester, onPick: (d) => picked = d);

    await tester.enterText(find.byKey(const Key('dob_day')), '31');
    await tester.enterText(find.byKey(const Key('dob_month')), '02');
    await tester.enterText(find.byKey(const Key('dob_year')), '2000');
    await tester.pump();

    expect(picked, isNull);
  });

  testWidgets('P2-a: chưa nhập đủ 3 ô → không onPick', (tester) async {
    DateTime? picked;
    await pumpStep(tester, onPick: (d) => picked = d);

    await tester.enterText(find.byKey(const Key('dob_day')), '15');
    await tester.enterText(find.byKey(const Key('dob_month')), '06');
    await tester.pump();

    expect(picked, isNull);
  });
}
