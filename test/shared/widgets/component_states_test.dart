import 'dart:ui' as ui;

import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_shadows.dart';
import 'package:cung_hat/core/theme/app_spacing.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/gradient_button.dart';
import 'package:cung_hat/shared/widgets/otp_input.dart';
import 'package:cung_hat/shared/widgets/pressable.dart';
import 'package:cung_hat/shared/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {bool disableAnimations = false}) => MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('primary CTA keeps a 2px border and hard shadow', (tester) async {
    await tester.pumpWidget(
      host(GradientButton(onPressed: () {}, child: const Text('Tiếp tục'))),
    );
    final decorated = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(GradientButton),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final box = decorated.decoration as BoxDecoration;
    expect((box.border! as Border).top.width, 2);
    expect(box.boxShadow, <BoxShadow>[AppShadows.hard]);
  });

  testWidgets('empty state uses a hard-surface icon without blur', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const EmptyState(icon: Icons.wifi_off, title: 'Mất kết nối'),
        disableAnimations: true,
      ),
    );
    final boxes = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(EmptyState),
        matching: find.byType(Container),
      ),
    );
    final decorations = boxes
        .map((box) => box.decoration)
        .whereType<BoxDecoration>();
    final hardSurface = decorations.singleWhere(
      (box) => box.boxShadow?.contains(AppShadows.hard) ?? false,
    );
    final border = hardSurface.border! as Border;
    expect(hardSurface.color, AppColors.surface);
    expect(border.top.color, AppColors.ink);
    expect(border.top.width, 2);
    expect(
      hardSurface.borderRadius,
      BorderRadius.circular(AppSpacing.radiusCard),
    );
    expect(
      decorations
          .expand((box) => box.boxShadow ?? const <BoxShadow>[])
          .any((shadow) => shadow.blurRadius > 0),
      isFalse,
    );
    expect(decorations.any((box) => box.gradient != null), isFalse);
  });

  testWidgets('OTP cells use the shared 2px ink border', (tester) async {
    await tester.pumpWidget(host(OtpInput(onChanged: (_) {})));
    final cells = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(cells, hasLength(6));
    for (final cell in cells) {
      final box = cell.decoration! as BoxDecoration;
      expect((box.border! as Border).top.width, 2);
      expect(
        (box.border! as Border).top.color,
        anyOf(AppColors.ink, AppColors.primary),
      );
      expect(box.boxShadow, isNull);
    }
  });

  testWidgets('OTP cell transitions stop when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(OtpInput(onChanged: (_) {}), disableAnimations: true),
    );

    final cells = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(cells, hasLength(6));
    for (final cell in cells) {
      expect(cell.duration, Duration.zero);
    }
  });

  testWidgets('press feedback has no duration when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Pressable(onTap: () {}, child: const Text('Press')),
        disableAnimations: true,
      ),
    );

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      Duration.zero,
    );
  });

  testWidgets('pressable paints a visible ring for keyboard focus', (
    tester,
  ) async {
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousStrategy;
    });

    const boundaryKey = Key('focused_pressable_boundary');
    await tester.pumpWidget(
      host(
        RepaintBoundary(
          key: boundaryKey,
          child: Pressable(
            onTap: () {},
            child: const SizedBox(
              width: 80,
              height: 48,
              child: ColoredBox(
                color: AppColors.primary,
                child: Center(
                  child: SizedBox.square(
                    dimension: 12,
                    child: ColoredBox(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    late ui.Image image;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: 1);
    });
    addTearDown(image.dispose);
    late ByteData bytes;
    await tester.runAsync(() async {
      bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });

    Color pixelAt(int x, int y) {
      final offset = (y * image.width + x) * 4;
      return Color.fromARGB(
        bytes.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      );
    }

    expect(
      pixelAt(40, 24),
      AppColors.onPrimary,
      reason: 'The focus paint must not cover the focused child content.',
    );
    expect(pixelAt(1, 24), AppColors.secondary);
    expect(pixelAt(4, 24), AppColors.ink);
  });

  testWidgets('loading skeleton uses a flat fill without a gradient', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const Skeleton(width: 120), disableAnimations: true),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(Skeleton),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);
    expect(decoration.gradient, isNull);
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('loading skeleton stops and resumes with motion preference', (
    tester,
  ) async {
    final disableAnimations = ValueNotifier(false);
    addTearDown(disableAnimations.dispose);
    const skeletonKey = Key('motion_skeleton');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ValueListenableBuilder<bool>(
          valueListenable: disableAnimations,
          builder: (context, disabled, _) => MediaQuery(
            data: MediaQueryData(disableAnimations: disabled),
            child: const Scaffold(body: Skeleton(key: skeletonKey, width: 120)),
          ),
        ),
      ),
    );

    Color color() {
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(skeletonKey),
          matching: find.byType(Container),
        ),
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    final enabledStart = color();
    await tester.pump(const Duration(milliseconds: 75));
    expect(color(), isNot(enabledStart));

    disableAnimations.value = true;
    await tester.pump();
    final disabledColor = color();
    await tester.pump(const Duration(milliseconds: 75));
    expect(color(), disabledColor);

    disableAnimations.value = false;
    await tester.pump();
    final resumedStart = color();
    await tester.pump(const Duration(milliseconds: 75));
    expect(color(), isNot(resumedStart));
  });
}
