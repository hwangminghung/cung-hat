import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/chat/presentation/chat_timeline.dart';

// Kỳ vọng tính ĐỘNG theo TZ máy chạy test (CI khác TZ VN) — không hardcode
// giờ local, cùng quy ước với keo_match_sheet_test.
void main() {
  String two(int v) => v.toString().padLeft(2, '0');

  test('bubbleTime đổi UTC sang giờ local HH:mm', () {
    const iso = '2026-07-06T16:09:00Z';
    final local = DateTime.parse(iso).toLocal();
    expect(bubbleTime(iso), '${two(local.hour)}:${two(local.minute)}');
  });

  test('dayLabelBetween: tin đầu tiên luôn có nhãn ngày d/M', () {
    final now = DateTime(2099, 1, 1);
    final local = DateTime.parse('2026-07-06T10:00:00Z').toLocal();
    expect(
      dayLabelBetween(null, '2026-07-06T10:00:00Z', now),
      '${local.day}/${local.month}',
    );
  });

  test('dayLabelBetween: cùng ngày local -> null (không chèn nhãn)', () {
    final now = DateTime(2099, 1, 1);
    expect(
      dayLabelBetween('2026-07-06T09:00:00Z', '2026-07-06T10:05:00Z', now),
      isNull,
    );
  });

  test('dayLabelBetween: đổi ngày -> nhãn d/M của tin sau', () {
    final now = DateTime(2099, 1, 1);
    final local = DateTime.parse('2026-07-07T10:00:00Z').toLocal();
    expect(
      dayLabelBetween('2026-07-06T10:00:00Z', '2026-07-07T10:00:00Z', now),
      '${local.day}/${local.month}',
    );
  });

  test('dayLabelBetween: tin của hôm nay -> "Hôm nay"', () {
    final nowLocal = DateTime.now();
    final todayIso = nowLocal.toUtc().toIso8601String();
    expect(
      dayLabelBetween('2026-01-01T10:00:00Z', todayIso, nowLocal),
      'Hôm nay',
    );
  });
}
