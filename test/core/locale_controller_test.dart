import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cung_hat/core/l10n/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mặc định theo initialLocaleProvider (null = hệ thống)', () {
    final c = ProviderContainer();
    expect(c.read(localeControllerProvider), isNull);
  });

  test('set(en) → state đổi + lưu prefs; set(null) → xoá pref', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    await c.read(localeControllerProvider.notifier).set(const Locale('en'));
    expect(c.read(localeControllerProvider), const Locale('en'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kLocaleOverridePrefKey), 'en');

    await c.read(localeControllerProvider.notifier).set(null);
    expect(c.read(localeControllerProvider), isNull);
    expect(prefs.getString(kLocaleOverridePrefKey), isNull);
  });

  test('loadSavedLocaleOverride đọc pref đã lưu', () async {
    SharedPreferences.setMockInitialValues({kLocaleOverridePrefKey: 'vi'});
    expect(await loadSavedLocaleOverride(), const Locale('vi'));
  });

  test('seed qua initialLocaleProvider', () {
    final c = ProviderContainer(
      overrides: [initialLocaleProvider.overrideWithValue(const Locale('en'))],
    );
    expect(c.read(localeControllerProvider), const Locale('en'));
  });
}
