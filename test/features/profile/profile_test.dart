import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

void main() {
  test('Profile.fromJson maps the sanitized RPC shape', () {
    final p = Profile.fromJson({
      'id': 'u1', 'display_name': 'Mai', 'full_name': 'Tran Mai',
      'dob': '2000-01-01', 'age_verified': true, 'bio': 'hi', 'language': 'vi',
    });
    expect(p.id, 'u1');
    expect(p.displayName, 'Mai');
    expect(p.ageVerified, isTrue);
  });

  test('Profile equality is value-based (freezed)', () {
    const a = Profile(id: 'u1', ageVerified: false, language: 'vi');
    const b = Profile(id: 'u1', ageVerified: false, language: 'vi');
    expect(a, b);
  });
}
