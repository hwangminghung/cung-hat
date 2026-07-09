/// Dich cunghat:// URI sang route noi bo. Null = khong nhan dien duoc (bo qua).
///
/// Token duoc re-encode bang [Uri.encodeComponent] truoc khi interpolate:
/// `pathSegments` da percent-DECODE, nen token chua `..%2F..%2Fadmin` se thanh
/// `../../admin` — interpolate tho se bi go_router chuan hoa thanh `/admin`
/// (route injection). Encode lai giu token trong dung 1 path segment.
// TODO(P7): map them https universal link (xem plan p7-launch) — hien chi nhan scheme cunghat.
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
