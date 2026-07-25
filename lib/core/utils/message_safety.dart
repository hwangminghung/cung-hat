const _riskyPatterns = <String>[
  'số tài khoản',
  'tài khoản ngân hàng',
  'chuyển khoản',
  'mã otp',
  'vay tiền',
  'bank account',
  'send money',
  'transfer',
  'otp code',
  'crypto',
];

bool messageLooksUnsafe(String text) {
  final t = text.toLowerCase();
  return _riskyPatterns.any(t.contains);
}
