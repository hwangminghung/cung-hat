/// Dich cunghat:// URI sang route noi bo. Null = khong nhan dien duoc (bo qua).
///
/// Token duoc re-encode bang [Uri.encodeComponent] truoc khi interpolate:
/// `pathSegments` da percent-DECODE, nen token chua `..%2F..%2Fadmin` se thanh
/// `../../admin` — interpolate tho se bi go_router chuan hoa thanh `/admin`
/// (route injection). Encode lai giu token trong dung 1 path segment.
// TODO(P7): map them https universal link (xem plan p7-launch) — hien chi nhan scheme cunghat.
/// Dich mot LOCATION do go_router dua toi, neu no thuc ra la URI `cunghat://`.
///
/// [DEEPLINK 2026-07-26] Co HAI thu cung nhan link toi: `app_links` (dich dung
/// qua [deepLinkLocation]) va chinh go_router — no tu nghe kenh route cua
/// platform. Khi app DANG CHAY, go_router nuot URI tho truoc khi app_links kip
/// dich, va vi 'cunghat://keo/shared/x' khong khop route nao nen user thay
/// "Page Not Found / GoException". Cold start khong dinh vi `getInitialLink()`
/// chay truoc. Vi vay router phai tu ve duoc, khong the chi dua vao app_links.
///
/// Tra null = khong phai viec cua ham nay, giu nguyen location.
/// Tra '/' = la link cunghat nhung khong nhan dien duoc → ve home, KHONG de
/// user roi vao man loi ky thuat.
String? normalizeDeepLinkLocation(String location) {
  if (!location.startsWith('cunghat://')) return null;
  final uri = Uri.tryParse(location);
  if (uri == null) return '/';
  return deepLinkLocation(uri) ?? '/';
}

String? deepLinkLocation(Uri uri) {
  if (uri.scheme != 'cunghat') return null;
  final segs = uri.pathSegments;
  if (uri.host == 'plan' && segs.isNotEmpty && segs.first.isNotEmpty) {
    return '/plan/shared/${Uri.encodeComponent(segs.first)}';
  }
  if (uri.host == 'keo' &&
      segs.length >= 2 &&
      segs.first == 'shared' &&
      segs[1].isNotEmpty) {
    return '/keo/shared/${Uri.encodeComponent(segs[1])}';
  }
  return null;
}
