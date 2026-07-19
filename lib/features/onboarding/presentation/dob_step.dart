import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/hard_card.dart';

bool isAdult(DateTime dob, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final eighteenth = DateTime(dob.year + 18, dob.month, dob.day);
  return !n.isBefore(eighteenth);
}

/// P2: 3 ô NHẬP trực tiếp Ngày/Tháng/Năm thay modal date picker — picker
/// brittle (khó automate, nhiều chạm) là điểm rơi funnel ở bước 1 onboarding.
/// [onPick] chỉ được gọi khi 3 ô hợp lệ và là ngày CÓ THẬT (roundtrip
/// DateTime khớp từng phần — chặn 31/02 bị normalize thành 02/03).
class DobStep extends StatefulWidget {
  const DobStep({super.key, required this.dob, required this.onPick});
  final DateTime? dob;
  final ValueChanged<DateTime> onPick;

  @override
  State<DobStep> createState() => _DobStepState();
}

class _DobStepState extends State<DobStep> {
  late final _day = TextEditingController(
    text: widget.dob?.day.toString().padLeft(2, '0') ?? '',
  );
  late final _month = TextEditingController(
    text: widget.dob?.month.toString().padLeft(2, '0') ?? '',
  );
  late final _year = TextEditingController(
    text: widget.dob?.year.toString() ?? '',
  );
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  void _tryPick() {
    if (_year.text.length < 4) return;
    final d = int.tryParse(_day.text);
    final m = int.tryParse(_month.text);
    final y = int.tryParse(_year.text);
    if (d == null || m == null || y == null || y < 1900) return;
    final date = DateTime(y, m, d);
    // Ngày không tồn tại (31/02…) bị DateTime normalize — roundtrip phải khớp.
    if (date.year != y || date.month != m || date.day != d) return;
    if (date.isAfter(DateTime.now())) return;
    widget.onPick(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final ok = widget.dob != null && isAdult(widget.dob!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.onbStepDob ?? 'Ngày sinh',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n?.onbDobTitle ?? 'Bạn sinh ngày nào?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        HardCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const _DobArt(),
                _AgeNotice(
                  label:
                      l10n?.onbUnder18 ??
                      'Bạn phải đủ 18 tuổi để dùng ứng dụng.',
                ),
                const SizedBox(height: AppSpacing.md),
                // Key 'pick_dob_btn' GIỮ NGUYÊN làm mỏ neo cho
                // integration_test (app_test.dart chỉ find, không tap).
                Row(
                  key: const Key('pick_dob_btn'),
                  children: [
                    Expanded(
                      child: _DobField(
                        fieldKey: const Key('dob_day'),
                        controller: _day,
                        label: l10n?.onbDobDay ?? 'Ngày',
                        hint: '--',
                        maxLength: 2,
                        onChanged: (v) {
                          if (v.length == 2) _monthFocus.requestFocus();
                          _tryPick();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DobField(
                        fieldKey: const Key('dob_month'),
                        controller: _month,
                        focusNode: _monthFocus,
                        label: l10n?.onbDobMonth ?? 'Tháng',
                        hint: '--',
                        maxLength: 2,
                        onChanged: (v) {
                          if (v.length == 2) _yearFocus.requestFocus();
                          _tryPick();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DobField(
                        fieldKey: const Key('dob_year'),
                        controller: _year,
                        focusNode: _yearFocus,
                        label: l10n?.onbDobYear ?? 'Năm',
                        hint: '----',
                        maxLength: 4,
                        onChanged: (v) {
                          if (v.length == 4) _yearFocus.unfocus();
                          _tryPick();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (widget.dob != null && !ok)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              l10n?.onbUnder18 ?? 'Bạn phải đủ 18 tuổi để dùng ứng dụng.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _DobArt extends StatelessWidget {
  const _DobArt();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 104,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, color: AppColors.ink, size: 52),
          SizedBox(width: AppSpacing.lg),
          Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 56),
        ],
      ),
    );
  }
}

class _AgeNotice extends StatelessWidget {
  const _AgeNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondaryTint,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DobField extends StatelessWidget {
  const _DobField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLength,
    required this.onChanged,
    this.focusNode,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLength),
            ],
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
