import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';

/// Tap wrapper with a subtle scale-down press feedback (0.97).
/// Uses Transform.scale so layout bounds never shift.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final interactive =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    final pressDuration = MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero
        : AppMotion.fast;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive ? (_) => _set(true) : null,
      onTapUp: interactive ? (_) => _set(false) : null,
      onTapCancel: interactive ? () => _set(false) : null,
      onTap: interactive ? widget.onTap : null,
      onLongPress: interactive ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScale : 1.0,
        duration: pressDuration,
        curve: AppMotion.enterCurve,
        child: widget.child,
      ),
    );
  }
}
