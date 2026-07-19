import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({
    super.key,
    required this.child,
    this.maxWidth = 430,
    this.padding = EdgeInsets.zero,
    this.avoidKeyboard = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool avoidKeyboard;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = avoidKeyboard ? media.viewInsets.bottom : 0.0;
    final duration = media.disableAnimations ? Duration.zero : AppMotion.base;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: AnimatedPadding(
              duration: duration,
              curve: AppMotion.enterCurve,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
