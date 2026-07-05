import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Six separate single-digit boxes backed by one hidden TextField.
/// Exposes the entered string via [onChanged]; fires [onCompleted] at 6 digits.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
  });
  final int length;
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
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
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
            GestureDetector(
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
    final borderColor = isFilled || isActive
        ? AppColors.primary
        : AppColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: width,
      height: AppSpacing.inputHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        border: Border.all(color: borderColor, width: isFilled ? 1.5 : 1),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(value, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
