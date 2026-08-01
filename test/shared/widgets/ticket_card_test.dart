import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_shadows.dart';
import 'package:cung_hat/core/theme/app_spacing.dart';
import 'package:cung_hat/shared/widgets/ticket_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

TicketCardPainter _painter(WidgetTester tester) {
  final paintFinder = find.descendant(
    of: find.byType(TicketCard),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.foregroundPainter is TicketCardPainter,
    ),
  );
  expect(paintFinder, findsOneWidget);
  return (tester.widget<CustomPaint>(paintFinder).foregroundPainter!
      as TicketCardPainter);
}

void main() {
  testWidgets(
    'TicketCard foreground details stay clipped over full-bleed content',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          TicketCard(
            padding: EdgeInsets.zero,
            perforationPosition: 0.01,
            child: SizedBox(
              height: 80,
              child: ColoredBox(color: AppColors.primary),
            ),
          ),
        ),
      );

      final paintFinder = find.descendant(
        of: find.byType(TicketCard),
        matching: find.byType(CustomPaint),
      );
      final paint = tester.widget<CustomPaint>(paintFinder);
      expect(paint.painter, isNull);
      expect(paint.foregroundPainter, isA<TicketCardPainter>());
      expect(
        find.ancestor(
          of: paintFinder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ClipPath && widget.clipper is TicketCardClipper,
          ),
        ),
        findsOneWidget,
      );

      final painter = paint.foregroundPainter! as TicketCardPainter;
      expect(painter.perforationPosition, 0.01);
      expect(painter.showPerforation, isTrue);
    },
  );

  testWidgets(
    'TicketCard clips its child and paints the configured perforation',
    (tester) async {
      const childKey = ValueKey('ticket-content');
      const padding = EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      );

      await tester.pumpWidget(
        _wrap(
          const TicketCard(
            padding: padding,
            perforationPosition: 0.31,
            child: Text('19:30', key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byKey(childKey),
          matching: find.byWidgetPredicate(
            (widget) => widget is Padding && widget.padding == padding,
          ),
        ),
        findsOneWidget,
      );

      final clipFinder = find.descendant(
        of: find.byType(TicketCard),
        matching: find.byType(ClipPath),
      );
      expect(clipFinder, findsNWidgets(2));
      expect(
        tester
            .widgetList<ClipPath>(clipFinder)
            .every((clip) => clip.clipper is TicketCardClipper),
        isTrue,
      );

      final painter = _painter(tester);
      expect(painter.showPerforation, isTrue);
      expect(painter.perforationPosition, 0.31);
      expect(painter.surfaceColor, AppColors.surface);
      expect(painter.outlineColor, AppColors.ink);
      expect(painter.outlineWidth, 2);

      final foregroundPaint = find.descendant(
        of: find.byType(TicketCard),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.foregroundPainter is TicketCardPainter,
        ),
      );
      expect(
        tester.getSize(foregroundPaint).width,
        320 - AppShadows.hard.offset.dx,
      );

      final shadow = tester.widget<Transform>(
        find.descendant(
          of: find.byType(TicketCard),
          matching: find.byType(Transform),
        ),
      );
      expect(shadow.transform.entry(0, 3), AppShadows.hard.offset.dx);
      expect(shadow.transform.entry(1, 3), AppShadows.hard.offset.dy);
    },
  );

  testWidgets('TicketCard can hide its perforation', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TicketCard(
          showPerforation: false,
          perforationPosition: 0.64,
          child: Text('Chi tiết kèo'),
        ),
      ),
    );

    final painter = _painter(tester);
    expect(painter.showPerforation, isFalse);
    expect(painter.perforationPosition, 0.64);
  });
}
