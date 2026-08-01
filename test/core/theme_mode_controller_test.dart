import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cung_hat/core/theme/theme_mode_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mặc định system; set dark → persist; set system → xoá pref', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeControllerProvider), ThemeMode.system);

    await container
        .read(themeModeControllerProvider.notifier)
        .set(ThemeMode.dark);
    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kThemeModePrefKey), 'dark');

    await container
        .read(themeModeControllerProvider.notifier)
        .set(ThemeMode.system);
    expect(prefs.getString(kThemeModePrefKey), isNull);
  });

  test('loadSavedThemeMode đọc lại giá trị đã lưu', () async {
    SharedPreferences.setMockInitialValues({kThemeModePrefKey: 'dark'});
    expect(await loadSavedThemeMode(), ThemeMode.dark);
    SharedPreferences.setMockInitialValues({kThemeModePrefKey: 'light'});
    expect(await loadSavedThemeMode(), ThemeMode.light);
    SharedPreferences.setMockInitialValues({});
    expect(await loadSavedThemeMode(), ThemeMode.system);
  });

  test('effectiveBrightness: user chọn thắng máy; system theo máy', () {
    final container = ProviderContainer(
      overrides: [
        platformBrightnessProvider.overrideWith((ref) => Brightness.dark),
      ],
    );
    addTearDown(container.dispose);

    // system → theo máy (dark).
    expect(container.read(effectiveBrightnessProvider), Brightness.dark);
    // user chọn light → thắng máy.
    container.read(themeModeControllerProvider.notifier).set(ThemeMode.light);
    expect(container.read(effectiveBrightnessProvider), Brightness.light);
  });
}
