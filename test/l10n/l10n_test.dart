import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('VI locale resolves comingSoon to "Sắp có"', () async {
    final l = await AppLocalizations.delegate.load(const Locale('vi'));
    expect(l.comingSoon, 'Sắp có');
  });

  // [L10N] Guard song ngữ: mọi key phải có ở CẢ 2 arb — thiếu VI thì user
  // Việt thấy tiếng Anh lẫn; thiếu EN thì gen-l10n fail (en là template).
  test('app_en.arb và app_vi.arb có cùng bộ key', () {
    Set<String> keysOf(String path) =>
        (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>).keys
            .where((k) => !k.startsWith('@'))
            .toSet();
    final en = keysOf('lib/l10n/app_en.arb');
    final vi = keysOf('lib/l10n/app_vi.arb');
    expect(vi.difference(en), isEmpty, reason: 'key chỉ có ở VI (thiếu EN)');
    expect(en.difference(vi), isEmpty, reason: 'key chỉ có ở EN (thiếu VI)');
  });

  test('EN locale resolves comingSoon', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(l.comingSoon, isNotEmpty);
  });
}
