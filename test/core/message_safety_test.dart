import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/utils/message_safety.dart';

void main() {
  test('flags risky outbound phrases', () {
    expect(messageLooksUnsafe('cho mình xin số tài khoản'), isTrue);
    expect(messageLooksUnsafe('send me your bank account'), isTrue);
  });
  test('passes normal chat', () {
    expect(messageLooksUnsafe('Tối nay đi hát nhé?'), isFalse);
  });
}
