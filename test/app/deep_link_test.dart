import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/deep_link.dart';

void main() {
  test('plan link -> /plan/shared/<token>', () {
    expect(
      deepLinkLocation(Uri.parse('cunghat://plan/abc123')),
      '/plan/shared/abc123',
    );
  });
  test('keo link -> /keo/shared/<token>', () {
    expect(
      deepLinkLocation(Uri.parse('cunghat://keo/shared/tok456')),
      '/keo/shared/tok456',
    );
  });
  test('scheme la -> null', () {
    expect(deepLinkLocation(Uri.parse('https://plan/abc')), isNull);
  });
  test('keo thieu token -> null', () {
    expect(deepLinkLocation(Uri.parse('cunghat://keo/shared')), isNull);
  });
  test('token chua %2F khong escape duoc sang route khac', () {
    expect(
      deepLinkLocation(Uri.parse('cunghat://plan/..%2F..%2Fadmin')),
      '/plan/shared/${Uri.encodeComponent('../../admin')}',
    );
  });
  test('keo trailing slash (token rong) -> null', () {
    expect(deepLinkLocation(Uri.parse('cunghat://keo/shared/')), isNull);
  });
  test('token binh thuong khong bi doi dang', () {
    expect(
      deepLinkLocation(Uri.parse('cunghat://plan/tok123')),
      '/plan/shared/tok123',
    );
  });

  // [DEEPLINK 2026-07-26] Do tren may: app DANG CHAY ma nhan link thi
  // go_router tu nghe kenh route cua platform va nuot URI THO
  // ('cunghat://keo/shared/xxx') truoc khi app_links kip dich -> man
  // "Page Not Found / GoException: no routes for location". Cold start
  // khong dinh vi getInitialLink() chay truoc. Nen router phai tu dich
  // duoc URI tho, khong the chi dua vao app_links.
  group('normalizeDeepLinkLocation (router tu ve duoc)', () {
    test('URI cunghat tho -> route noi bo', () {
      expect(
        normalizeDeepLinkLocation('cunghat://keo/shared/tok456'),
        '/keo/shared/tok456',
      );
      expect(
        normalizeDeepLinkLocation('cunghat://plan/abc123'),
        '/plan/shared/abc123',
      );
    });

    test('route noi bo giu nguyen', () {
      expect(normalizeDeepLinkLocation('/keo/shared/tok456'), isNull);
      expect(normalizeDeepLinkLocation('/'), isNull);
      expect(normalizeDeepLinkLocation('/settings/blocked'), isNull);
    });

    test('cunghat khong nhan dien duoc -> ve home thay vi Page Not Found', () {
      expect(normalizeDeepLinkLocation('cunghat://keo/shared'), '/');
      expect(normalizeDeepLinkLocation('cunghat://linh-tinh'), '/');
    });

    test('scheme khac khong dung toi', () {
      expect(normalizeDeepLinkLocation('https://cunghat.vn/keo'), isNull);
    });
  });
}
