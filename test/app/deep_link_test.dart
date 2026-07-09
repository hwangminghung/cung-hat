import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/deep_link.dart';

void main() {
  test('plan link -> /plan/shared/<token>', () {
    expect(deepLinkLocation(Uri.parse('cunghat://plan/abc123')), '/plan/shared/abc123');
  });
  test('keo link -> /keo/shared/<token>', () {
    expect(deepLinkLocation(Uri.parse('cunghat://keo/shared/tok456')), '/keo/shared/tok456');
  });
  test('scheme la -> null', () {
    expect(deepLinkLocation(Uri.parse('https://plan/abc')), isNull);
  });
  test('keo thieu token -> null', () {
    expect(deepLinkLocation(Uri.parse('cunghat://keo/shared')), isNull);
  });
  test('token chua %2F khong escape duoc sang route khac', () {
    expect(deepLinkLocation(Uri.parse('cunghat://plan/..%2F..%2Fadmin')),
        '/plan/shared/${Uri.encodeComponent('../../admin')}');
  });
  test('keo trailing slash (token rong) -> null', () {
    expect(deepLinkLocation(Uri.parse('cunghat://keo/shared/')), isNull);
  });
  test('token binh thuong khong bi doi dang', () {
    expect(deepLinkLocation(Uri.parse('cunghat://plan/tok123')), '/plan/shared/tok123');
  });
}
