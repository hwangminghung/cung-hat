import 'package:flutter/material.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

bool isAdult(DateTime dob, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final eighteenth = DateTime(dob.year + 18, dob.month, dob.day);
  return !n.isBefore(eighteenth);
}

class DobStep extends StatelessWidget {
  const DobStep({super.key, required this.dob, required this.onPick});
  final DateTime? dob;
  final ValueChanged<DateTime> onPick;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final ok = dob != null && isAdult(dob!);
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
        const _DobArt(),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.ink, width: 2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            boxShadow: const [AppShadows.hard],
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
                  l10n?.onbUnder18 ?? 'Bạn phải đủ 18 tuổi để dùng ứng dụng.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('pick_dob_btn'),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            onTap: () => _pickDate(context),
            child: Row(
              children: [
                Expanded(
                  child: _DatePart(
                    value: dob?.day.toString().padLeft(2, '0') ?? '--',
                    label: l10n?.onbDobDay ?? 'Ngày',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DatePart(
                    value: dob?.month.toString().padLeft(2, '0') ?? '--',
                    label: l10n?.onbDobMonth ?? 'Tháng',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DatePart(
                    value: dob?.year.toString() ?? '----',
                    label: l10n?.onbDobYear ?? 'Năm',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (dob != null && !ok)
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
    return Center(
      child: Container(
        width: 190,
        height: 104,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.ink, width: 2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: const [AppShadows.hard],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, color: AppColors.ink, size: 52),
            SizedBox(width: AppSpacing.lg),
            Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 56),
          ],
        ),
      ),
    );
  }
}

class _DatePart extends StatelessWidget {
  const _DatePart({required this.value, required this.label});

  final String value;
  final String label;

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
        boxShadow: const [AppShadows.hard],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
