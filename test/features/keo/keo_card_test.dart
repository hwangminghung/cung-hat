import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/presentation/keo_card.dart';

void main() {
  testWidgets('KeoCard renders title, meta and genres', (tester) async {
    const keo = Keo(
      id: '1', title: 'Hát K-Pop cuối tuần', distanceBand: '<1',
      sizeTarget: 4, slotsFilled: 1, genres: ['K-Pop'], hostName: 'Minh',
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: KeoCard(keo: keo)),
    ));
    expect(find.text('Hát K-Pop cuối tuần'), findsOneWidget);
    expect(find.text('1/4 người'), findsOneWidget);
    expect(find.text('cách <1 km'), findsOneWidget);
    expect(find.text('K-Pop'), findsOneWidget);
  });
}
