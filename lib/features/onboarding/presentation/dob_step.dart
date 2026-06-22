import 'package:flutter/material.dart';

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
    final ok = dob != null && isAdult(dob!);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Bạn sinh ngày nào? (phải đủ 18 tuổi)'),
        const SizedBox(height: 12),
        FilledButton.tonal(
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
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Bạn phải đủ 18 tuổi để dùng ứng dụng.',
                style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}
