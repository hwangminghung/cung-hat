/// Dich cunghat:// URI sang route noi bo. Null = khong nhan dien duoc (bo qua).
String? deepLinkLocation(Uri uri) {
  if (uri.scheme != 'cunghat') return null;
  final segs = uri.pathSegments;
  if (uri.host == 'plan' && segs.isNotEmpty) return '/plan/shared/${segs.first}';
  if (uri.host == 'keo' && segs.length >= 2 && segs.first == 'shared') {
    return '/keo/shared/${segs[1]}';
  }
  return null;
}
