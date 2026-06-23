import 'package:flutter/material.dart';
import 'package:cung_hat/l10n/app_localizations.dart';

bool isAdult(DateTime dob, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final eighteenth = DateTime(dob.year + 18, dob.month, dob.day);
  return !n.isBefore(eighteenth);
}

class DobStep extends StatelessWidget {
  const DobStep({super.key, required this.dob, required this.onPick});
  final DateTime? dob;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final ok = dob != null && isAdult(dob!);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(l10n?.onbDobTitle ?? 'Bạn sinh ngày nào? (phải đủ 18 tuổi)'),
        const SizedBox(height: 12),
        FilledButton.tonal(
          key: const Key('pick_dob_btn'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
              initialDate: DateTime(2000),
            );
            if (picked != null) onPick(picked);
          },
          child: Text(dob == null ? 'Chọn ngày sinh'
              : '${dob!.day}/${dob!.month}/${dob!.year}'),
        ),
        if (dob != null && !ok)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n?.onbUnder18 ?? 'Bạn phải đủ 18 tuổi để dùng ứng dụng.',
                style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}
