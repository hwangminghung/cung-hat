import 'package:intl/intl.dart';

/// Dinh dang thoi diem ISO cua server thanh 'HH:mm · ngay-theo-locale'.
///
/// [AUDIT] `plans.scheduled_at` duoc doc ra duoi dang String va truoc day
/// duoc noi thang vao Text(), nen man hinh Ke hoach in nguyen
/// '2026-07-27T09:12:36.502289+00:00' cho user doc. Dat o day thay vi trong
/// widget vi ca PlanScreen lan SharedPlanScreen deu can.
///
/// [A11Y-AUDIT 2026-08-01] Them [locale]: ngay truoc day luon la 'd/M/y'
/// kieu VN bat ke ngon ngu — may EN mong '8/1/2026' lai thay '1/8/2026',
/// doc nham thang/ngay. Caller truyen
/// `Localizations.localeOf(context).toString()`; null = giu format cu
/// (duong lui cho cho goi ngoai widget tree).
///
/// Tra ve null khi khong parse duoc de caller tu chon fallback — khong bao
/// gio tu y in lai chuoi tho.
String? formatLocalDateTime(String? iso, {String? locale}) {
  final parsed = DateTime.tryParse(iso ?? '');
  if (parsed == null) return null;
  final local = parsed.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  final time = '${two(local.hour)}:${two(local.minute)}';
  // Gio GIU quy uoc HH:mm cua he (KeoCard/KeoDetail) o moi locale —
  // DateFormat.Hm('vi') tra '9:05' mat so 0 dan; chi phan NGAY theo locale.
  if (locale != null) {
    return '$time · ${DateFormat.yMd(locale).format(local)}';
  }
  return '$time · ${local.day}/${local.month}/${local.year}';
}
