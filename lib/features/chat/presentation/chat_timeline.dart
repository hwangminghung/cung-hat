import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Giờ local 'HH:mm' của một tin nhắn (createdAt ISO UTC từ DB).
String bubbleTime(String createdAtIso) {
  final local = DateTime.parse(createdAtIso).toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

/// Nhãn ngày chèn TRƯỚC tin [createdAtIso] khi nó khác ngày (local) với tin
/// đứng trước ([prevCreatedAtIso] null = tin đầu danh sách → luôn có nhãn).
/// Trùng ngày với [now] → 'Hôm nay', còn lại 'd/M'. Trả null khi cùng ngày.
String? dayLabelBetween(
  String? prevCreatedAtIso,
  String createdAtIso,
  DateTime now, {
  String today = 'Hôm nay',
}) {
  final local = DateTime.parse(createdAtIso).toLocal();
  if (prevCreatedAtIso != null) {
    final prev = DateTime.parse(prevCreatedAtIso).toLocal();
    final sameDay =
        prev.year == local.year &&
        prev.month == local.month &&
        prev.day == local.day;
    if (sameDay) return null;
  }
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  return isToday ? today : '${local.day}/${local.month}';
}

/// Vạch ngày giữa dòng chat — dùng chung chat 1-1 và chat nhóm.
class DayDivider extends StatelessWidget {
  const DayDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
