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
    expect(box.boxShadow, const <BoxShadow>[AppShadows.hard]);
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
