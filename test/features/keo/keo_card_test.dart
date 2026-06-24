import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/presentation/keo_card.dart';

void main() {
  testWidgets('keo card shows title, slots, distance band', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: KeoCard(
      keo: Keo(id: 'k1', title: 'Hát tối T7', distanceBand: '1-3',
        sizeTarget: 4, slotsFilled: 2, hostName: 'Mai'),
    ))));
    expect(find.text('Hát tối T7'), findsOneWidget);
    expect(find.textContaining('2/4'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
  });
}
