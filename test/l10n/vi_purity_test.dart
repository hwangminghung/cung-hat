import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Vòng cuối UI review 2026-07-17: chặn các cụm Việt-Anh đã dọn quay trở lại
/// app_vi.arb. Chỉ soi VALUE hiển thị cho người dùng — bỏ qua key, metadata
/// (@...), placeholder và tên lựa chọn ngôn ngữ 'English'. Từ được phép giữ:
/// Cùng Hát, Pro, K-pop, V-pop, MoMo, ZaloPay.
void main() {
  test('app_vi.arb không còn cụm Việt-Anh bị cấm', () {
    final raw = File('lib/l10n/app_vi.arb').readAsStringSync();
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final banned = <String, RegExp>{
      'boost kèo': RegExp('boost kèo', caseSensitive: false),
      'Gói Free': RegExp('Gói Free'),
      'Location': RegExp(r'\bLocation\b'),
      'Link không': RegExp('Link không'),
      'Host:': RegExp('Host:'),
      'chat nhóm': RegExp('chat nhóm', caseSensitive: false),
      // Mở rộng cùng tinh thần: các từ đã Việt hóa toàn cục.
      'boost (đứng riêng)': RegExp(r'\bboost\b', caseSensitive: false),
      'Online (đứng riêng)': RegExp(r'\bonline\b', caseSensitive: false),
      'Link đã': RegExp('Link đã'),
    };

    final violations = <String>[];
    data.forEach((key, value) {
      if (key.startsWith('@') || value is! String) return;
      if (value == 'English') return; // tên ngôn ngữ hiển thị bằng chính nó
      for (final entry in banned.entries) {
        if (entry.value.hasMatch(value)) {
          violations.add('$key ("${entry.key}"): $value');
        }
      }
    });

    expect(
      violations,
      isEmpty,
      reason:
          'Các value sau trong app_vi.arb chứa cụm Việt-Anh bị cấm:\n'
          '${violations.join('\n')}',
    );
  });
}
