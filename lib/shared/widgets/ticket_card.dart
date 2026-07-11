import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// A notched retro ticket surface with an optional tear-off perforation.
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.showPerforation = true,
    this.perforationPosition = 0.28,
  }) : assert(
         perforationPosition > 0 && perforationPosition < 1,
         'perforationPosition must be between 0 and 1.',
       );

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showPerforation;

  /// Horizontal position of the vertical perforation as a width fraction.
  final double perforationPosition;

  @override
  Widget build(BuildContext context) {
    const clipper = TicketCardClipper();

    return Padding(
      padding: EdgeInsets.only(
        right: AppShadows.hard.offset.dx,
        bottom: AppShadows.hard.offset.dy,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: AppShadows.hard.offset,
              child: const ClipPath(
                clipper: clipper,
                child: ColoredBox(color: AppShadows.hardColor),
              ),
            ),
          ),
          CustomPaint(
            painter: TicketCardPainter(
              showPerforation: showPerforation,
              perforationPosition: perforationPosition,
            ),
            child: ClipPath(
              clipper: clipper,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuts the rounded ticket silhouette and its symmetric edge notches.
class TicketCardClipper extends CustomClipper<Path> {
  const TicketCardClipper({
    this.radius = AppSpacing.radiusCard,
    this.notchRadius = AppSpacing.sm,
  });

  final double radius;
  final double notchRadius;

  @override
  Path getClip(Size size) =>
      _ticketPath(size, radius: radius, notchRadius: notchRadius);

  @override
  bool shouldReclip(TicketCardClipper oldClipper) =>
      radius != oldClipper.radius || notchRadius != oldClipper.notchRadius;
}

/// Paints the cream ticket surface, ink outline, and optional perforation.
class TicketCardPainter extends CustomPainter {
  const TicketCardPainter({
    this.showPerforation = true,
    this.perforationPosition = 0.28,
    this.surfaceColor = AppColors.surface,
    this.outlineColor = AppColors.ink,
    this.outlineWidth = 2,
  }) : assert(
         perforationPosition > 0 && perforationPosition < 1,
         'perforationPosition must be between 0 and 1.',
       );

  final bool showPerforation;
  final double perforationPosition;
  final Color surfaceColor;
  final Color outlineColor;
  final double outlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _ticketPath(
      size,
      radius: AppSpacing.radiusCard,
      notchRadius: AppSpacing.sm,
      inset: outlineWidth / 2,
    );

    canvas.drawPath(path, Paint()..color = surfaceColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth,
    );

    if (!showPerforation) return;

    final x = size.width * perforationPosition;
    final start = AppSpacing.md;
    final end = size.height - AppSpacing.md;
    if (end <= start) return;

    final perforationPaint = Paint()
      ..color = outlineColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;

    const dashLength = AppSpacing.xs;
    const dashGap = AppSpacing.xs;
    for (var y = start; y < end; y += dashLength + dashGap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + dashLength, end)),
        perforationPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TicketCardPainter oldDelegate) =>
      showPerforation != oldDelegate.showPerforation ||
      perforationPosition != oldDelegate.perforationPosition ||
      surfaceColor != oldDelegate.surfaceColor ||
      outlineColor != oldDelegate.outlineColor ||
      outlineWidth != oldDelegate.outlineWidth;
}

Path _ticketPath(
  Size size, {
  required double radius,
  required double notchRadius,
  double inset = 0,
}) {
  final bounds = Rect.fromLTRB(
    inset,
    inset,
    size.width - inset,
    size.height - inset,
  );
  final ticket = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        bounds,
        Radius.circular(math.max(0, radius - inset)),
      ),
    );
  final notches = Path()
    ..addOval(
      Rect.fromCircle(
        center: Offset(bounds.left, size.height / 2),
        radius: notchRadius,
      ),
    )
    ..addOval(
      Rect.fromCircle(
        center: Offset(bounds.right, size.height / 2),
        radius: notchRadius,
      ),
    );

  return Path.combine(PathOperation.difference, ticket, notches);
}
