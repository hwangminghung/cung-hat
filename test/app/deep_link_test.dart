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
}
