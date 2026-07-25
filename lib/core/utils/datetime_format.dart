/// Dinh dang thoi diem ISO cua server thanh 'HH:mm · d/M/y' theo gio may.
///
/// [AUDIT] `plans.scheduled_at` duoc doc ra duoi dang String va truoc day
/// duoc noi thang vao Text(), nen man hinh Ke hoach in nguyen
/// '2026-07-27T09:12:36.502289+00:00' cho user doc. Dat o day thay vi trong
/// widget vi ca PlanScreen lan SharedPlanScreen deu can.
///
/// Quy uoc bam theo KeoCard/KeoDetail (`toLocal()` + dem 0), chi them nam vi
/// ke hoach co the cach xa ngay hom nay hon la khung gio cua keo.
///
/// Tra ve null khi khong parse duoc de caller tu chon fallback — khong bao gio
/// tu y in lai chuoi tho.
String? formatLocalDateTime(String? iso) {
  final parsed = DateTime.tryParse(iso ?? '');
  if (parsed == null) return null;
  final local = parsed.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}'
      ' · ${local.day}/${local.month}/${local.year}';
}
