import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/presentation/keo_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('KeoCard renders title, meta and genres', (tester) async {
    const keo = Keo(
      id: '1',
      title: 'K-Pop weekend',
      distanceBand: '<1',
      sizeTarget: 4,
      slotsFilled: 1,
      genres: ['K-Pop'],
      hostName: 'Minh',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: KeoCard(keo: keo)),
      ),
    );

    expect(find.text('K-Pop weekend'), findsOneWidget);
    expect(find.text('K-Pop'), findsOneWidget);
    expect(find.text('Minh'), findsOneWidget);
  });

  testWidgets('KeoCard shows the open join-mode chip', (tester) async {
    const keo = Keo(
      id: '2',
      title: 'Open keo',
      sizeTarget: 4,
      slotsFilled: 1,
      joinMode: 'open',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: KeoCard(keo: keo)),
      ),
    );

    expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
  });

  testWidgets('KeoCard shows boosted badge', (tester) async {
    const keo = Keo(
      id: '3',
      title: 'Keo noi bat',
      sizeTarget: 4,
      slotsFilled: 1,
      isBoosted: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: KeoCard(keo: keo)),
      ),
    );

    expect(find.text('Noi bat'), findsOneWidget);
  });
}
