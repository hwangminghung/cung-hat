import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('VI locale resolves comingSoon to "Sắp có"', () async {
    final l = await AppLocalizations.delegate.load(const Locale('vi'));
    expect(l.comingSoon, 'Sắp có');
  });
}
