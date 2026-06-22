import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/onboarding/presentation/consent_step.dart';

void main() {
  testWidgets('toggling a purpose reports its new value', (tester) async {
    final changes = <String, bool>{};
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ConsentStep(
      values: const {'location': false, 'matching': false},
      onChanged: (k, v) => changes[k] = v,
    ))));
    await tester.tap(find.byKey(const Key('consent_location')));
    await tester.pump();
    expect(changes['location'], isTrue);
  });
}
