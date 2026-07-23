import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

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
  bool _showFocusHighlight = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _setFocusHighlight(bool value) {
    if (_showFocusHighlight != value) {
      setState(() => _showFocusHighlight = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interactive =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    final pressDuration = MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero
        : AppMotion.fast;
    return FocusableActionDetector(
      enabled: interactive,
      onShowFocusHighlight: _setFocusHighlight,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: CustomPaint(
        foregroundPainter: _showFocusHighlight
            ? const _FocusRingPainter()
            : null,
        child: GestureDetector(
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
        ),
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter();

  static const _strokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outerPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..isAntiAlias = false;
    final innerPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..isAntiAlias = false;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(AppSpacing.radiusCard),
      ).deflate(1),
      outerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(AppSpacing.radiusCard),
      ).deflate(4),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) => false;
}
