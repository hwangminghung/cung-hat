import 'package:cung_hat/shared/widgets/responsive_frame.dart';
import 'package:cung_hat/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('centers a 430dp mobile surface on a wide viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveFrame(
          child: ColoredBox(
            key: Key('content'),
            color: Colors.orange,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('content'))).width, 430);
    expect(tester.getCenter(find.byKey(const Key('content'))).dx, 450);
  });

  testWidgets('uses the full width on a 360dp viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveFrame(child: SizedBox.expand(key: Key('content'))),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('content'))).width, 360);
  });

  testWidgets('animates the keyboard inset only when avoidance is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 240)),
          child: ResponsiveFrame(
            child: SizedBox(key: Key('content'), height: 100),
          ),
        ),
      ),
    );
    final padding = tester.widget<AnimatedPadding>(
      find.byType(AnimatedPadding),
    );
    expect(padding.padding, const EdgeInsets.only(bottom: 240));
    expect(padding.duration, AppMotion.base);
  });

  testWidgets('does not apply the keyboard inset when avoidance is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 240)),
          child: ResponsiveFrame(
            avoidKeyboard: false,
            child: SizedBox(key: Key('content'), height: 100),
          ),
        ),
      ),
    );

    final padding = tester.widget<AnimatedPadding>(
      find.byType(AnimatedPadding),
    );
    expect(padding.padding, EdgeInsets.zero);
  });

  testWidgets('removes the keyboard transition when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 240),
            disableAnimations: true,
          ),
          child: ResponsiveFrame(
            child: SizedBox(key: Key('content'), height: 100),
          ),
        ),
      ),
    );

    final padding = tester.widget<AnimatedPadding>(
      find.byType(AnimatedPadding),
    );
    expect(padding.padding, const EdgeInsets.only(bottom: 240));
    expect(padding.duration, Duration.zero);
  });
}
