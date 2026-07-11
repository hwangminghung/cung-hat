import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/shared/widgets/app_logo.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/otp_input.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('AppLogo shows wordmark and tagline', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppLogo(tagline: 'Kết bạn qua âm nhạc')),
    );
    expect(find.text('Cùng Hát'), findsOneWidget);
    expect(find.text('Kết bạn qua âm nhạc'), findsOneWidget);
  });

  testWidgets('EmptyState shows CTA and fires callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EmptyState(
          icon: Icons.groups,
          title: 'Chưa có kèo quanh đây',
          actionLabel: 'Tạo kèo',
          onAction: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.text('Tạo kèo'));
    expect(tapped, isTrue);
  });

  testWidgets('OtpInput reports completion at full length', (tester) async {
    String? done;
    await tester.pumpWidget(
      _wrap(OtpInput(onChanged: (_) {}, onCompleted: (v) => done = v)),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(done, '123456');
  });

  testWidgets('OtpInput exposes one labelled editable text field', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(OtpInput(semanticLabel: 'Mã 6 số', onChanged: (_) {})),
    );

    final otpSemantics = find.bySemanticsLabel('Mã 6 số');
    expect(otpSemantics, findsOneWidget);
    expect(
      tester.getSemantics(otpSemantics),
      isSemantics(
        label: 'Mã 6 số',
        isTextField: true,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}
