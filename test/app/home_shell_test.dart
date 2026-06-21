import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/home_shell.dart';

void main() {
  testWidgets('HomeShell shows 4 tabs and switches', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    expect(find.text('Đôi'), findsOneWidget);
    expect(find.text('Kèo'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
    await tester.tap(find.text('Kèo'));
    await tester.pumpAndSettle();
    expect(find.text('Kèo — sắp có'), findsOneWidget);
  });
}
