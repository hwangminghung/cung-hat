import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

/// Six separate single-digit boxes backed by one hidden TextField.
/// Exposes the entered string via [onChanged]; fires [onCompleted] at 6 digits.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    this.semanticLabel,
    required this.onChanged,
    this.onCompleted,
  });
  final int length;
  final String? semanticLabel;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.length * 46.0 + (widget.length - 1) * gap;
        final boxWidth =
            ((maxWidth - (widget.length - 1) * gap) / widget.length)
                .clamp(24.0, 46.0)
                .toDouble();

        return Stack(
          children: [
            SizedBox(
              height: AppSpacing.inputHeight,
              child: Opacity(
                opacity: 0,
                alwaysIncludeSemantics: true,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: widget.semanticLabel,
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  showCursor: false,
                  enableInteractiveSelection: false,
                  onChanged: (v) {
                    setState(() {});
                    widget.onChanged(v);
                    if (v.length == widget.length) {
                      widget.onCompleted?.call(v);
                    }
                  },
                ),
              ),
            ),
            ExcludeSemantics(
              child: GestureDetector(
                onTap: () => _focus.requestFocus(),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.length; i++) ...[
                      _DigitBox(
                        width: boxWidth,
                        value: i < _controller.text.length
                            ? _controller.text[i]
                            : '',
                        isActive: i == _controller.text.length,
                        isFilled: i < _controller.text.length,
                      ),
                      if (i != widget.length - 1) const SizedBox(width: gap),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.width,
    required this.value,
    required this.isActive,
    required this.isFilled,
  });

  final double width;
  final String value;
  final bool isActive;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final otpBorder = Border.all(
      color: isFilled || isActive ? AppColors.primary : AppColors.ink,
      width: 2,
    );
    final transitionDuration =
        MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero
        : AppMotion.exit;
    return AnimatedContainer(
      duration: transitionDuration,
      width: width,
      height: AppSpacing.inputHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        border: otpBorder,
      ),
      child: Text(value, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
