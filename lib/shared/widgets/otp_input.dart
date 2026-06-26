import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Six separate single-digit boxes backed by one hidden TextField.
/// Exposes the entered string via [onChanged]; fires [onCompleted] at 6 digits.
class OtpInput extends StatefulWidget {
  const OtpInput({super.key, this.length = 6, required this.onChanged, this.onCompleted});
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
    return Stack(
      children: [
        Opacity(
          opacity: 0,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              setState(() {});
              widget.onChanged(v);
              if (v.length == widget.length) widget.onCompleted?.call(v);
            },
          ),
        ),
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final filled = i < _controller.text.length;
              return Container(
                width: 46,
                height: AppSpacing.inputHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                  border: Border.all(
                      color: filled ? AppColors.primary : AppColors.border,
                      width: filled ? 1.5 : 1),
                ),
                child: Text(filled ? _controller.text[i] : '',
                    style: Theme.of(context).textTheme.titleLarge),
              );
            }),
          ),
        ),
      ],
    );
  }
}
