import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cung_hat/core/utils/datetime_format.dart';

void main() {
  // ISO khong kem offset => DateTime.parse coi la gio may, nen toLocal() la
  // no-op. Nho vay assert duoi day khong phu thuoc timezone cua CI.
  test('ISO gio may -> HH:mm · d/M/y', () {
    expect(formatLocalDateTime('2026-07-12T19:00:00'), '19:00 · 12/7/2026');
  });

  test('dem 0 cho gio va phut mot chu so', () {
    expect(formatLocalDateTime('2026-01-05T09:05:00'), '09:05 · 5/1/2026');
  });

  test('ISO UTC duoc quy ve gio may', () {
    final formatted = formatLocalDateTime('2026-07-12T19:00:00Z');
    expect(formatted, isNotNull);
    // Khong con dau vet ISO tho tren man hinh.
    expect(formatted, isNot(contains('T')));
    expect(formatted, isNot(contains('Z')));
    expect(
      formatted,
      matches(RegExp(r'^\d{2}:\d{2} · \d{1,2}/\d{1,2}/\d{4}$')),
    );
  });

  test('chuoi rong / null / rac -> null de caller tu quyet dinh', () {
    expect(formatLocalDateTime(null), isNull);
    expect(formatLocalDateTime(''), isNull);
    expect(formatLocalDateTime('khong-phai-ngay'), isNull);
  });

  // [A11Y-AUDIT] Ngay theo locale: vi = ngay/thang, en_US = thang/ngay.
  group('locale-aware', () {
    setUpAll(() async {
      await initializeDateFormatting('vi');
      await initializeDateFormatting('en_US');
    });

    test('vi -> 5/1/2026 (ngay truoc thang)', () async {
      expect(
        formatLocalDateTime('2026-01-05T09:05:00', locale: 'vi'),
        '09:05 · 5/1/2026',
      );
    });

    test('en_US -> 1/5/2026 (thang truoc ngay)', () async {
      expect(
        formatLocalDateTime('2026-01-05T09:05:00', locale: 'en_US'),
        '09:05 · 1/5/2026',
      );
    });

    test('khong locale -> format cu (duong lui)', () {
      expect(formatLocalDateTime('2026-01-05T09:05:00'), '09:05 · 5/1/2026');
    });
  });
}
