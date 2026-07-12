import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/presentation/keo_card.dart';
import 'package:cung_hat/shared/widgets/stamp_chip.dart';
import 'package:cung_hat/shared/widgets/ticket_card.dart';

void main() {
  testWidgets('KeoCard renders title, meta and genres', (tester) async {
    const keo = Keo(
      id: '1',
      title: 'Hát K-Pop cuối tuần',
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
    expect(find.text('Hát K-Pop cuối tuần'), findsOneWidget);
    expect(find.text('1/4 người'), findsOneWidget);
    expect(find.text('cách <1 km'), findsOneWidget);
    expect(find.text('K-Pop'), findsOneWidget);
    // default joinMode is 'approval'
    expect(find.text('Cần duyệt'), findsOneWidget);
    expect(find.byType(TicketCard), findsOneWidget);
    expect(find.widgetWithText(StampChip, 'Cần duyệt'), findsOneWidget);
    expect(find.widgetWithText(StampChip, 'K-Pop'), findsOneWidget);
  });

  testWidgets('KeoCard shows the open join-mode chip', (tester) async {
    const keo = Keo(
      id: '2',
      title: 'Hát mở',
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
    expect(find.text('Mở · vào là tham gia'), findsOneWidget);
  });

  testWidgets('KeoCard uses actual time, place, distance and host data', (
    tester,
  ) async {
    const keo = Keo(
      id: '3',
      title: 'V-Pop tối nay',
      areaLabel: 'Thủ Đức',
      distanceBand: '1-3',
      timeWindowStart: '2026-07-17T20:00:00',
      timeWindowEnd: '2026-07-17T22:00:00',
      sizeTarget: 5,
      slotsFilled: 3,
      hostName: 'Minh',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: KeoCard(keo: keo)),
      ),
    );

    final ticket = tester.widget<TicketCard>(find.byType(TicketCard));
    expect(ticket.showPerforation, isTrue);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);
    expect(find.text('Thủ Đức'), findsOneWidget);
    expect(find.text('cách 1-3 km'), findsOneWidget);
    expect(find.text('Minh'), findsOneWidget);
  });

  testWidgets('KeoCard stays readable at 320px with large text', (
    tester,
  ) async {
    const keo = Keo(
      id: '4',
      title: 'V-Pop tối nay cùng hội bạn',
      areaLabel: 'Thủ Đức, Hồ Chí Minh',
      distanceBand: '1-3',
      timeWindowStart: '2026-07-17T20:00:00',
      timeWindowEnd: '2026-07-17T22:00:00',
      sizeTarget: 5,
      slotsFilled: 3,
      genres: ['V-Pop'],
      hostName: 'Minh',
      joinMode: 'open',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(child: KeoCard(keo: keo)),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Mở · vào là tham gia'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);
  });
}
