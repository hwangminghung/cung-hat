import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/shared/widgets/otp_input.dart';

void main() {
  testWidgets('6 ô không overflow trong bề ngang 270', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 270,
            child: OtpInput(onChanged: (_) {}),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
