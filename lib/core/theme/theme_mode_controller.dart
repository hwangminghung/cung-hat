import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pref key cho giao diện ('light'/'dark'); vắng = theo hệ thống.
const kThemeModePrefKey = 'theme_mode';

/// Đọc lựa chọn đã lưu — gọi trong main() TRƯỚC runApp để seed
/// [initialThemeModeProvider] (không nháy theme frame đầu). Best-effort:
/// prefs hỏng/thiếu plugin (unit test cũ) → system.
Future<ThemeMode> loadSavedThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(kThemeModePrefKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  } catch (e) {
    debugPrint('theme mode load skipped: $e');
    return ThemeMode.system;
  }
}

/// Giá trị seed từ main (override trong ProviderScope).
final initialThemeModeProvider = Provider<ThemeMode>((_) => ThemeMode.system);

/// Brightness của HỆ THỐNG — [_CungHatAppState] cập nhật qua
/// WidgetsBindingObserver.didChangePlatformBrightness. Cần provider riêng vì
/// AppColors.select phải chạy TRƯỚC khi MaterialApp dựng (MediaQuery chưa có).
final platformBrightnessProvider = StateProvider<Brightness>(
  (_) => WidgetsBinding.instance.platformDispatcher.platformBrightness,
);

/// Nguồn sự thật giao diện trong app — cùng khuôn LocaleController:
/// system = theo máy, light/dark = user tự chọn trong Cài đặt (persist).
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.system) {
        await prefs.remove(kThemeModePrefKey);
      } else {
        await prefs.setString(
          kThemeModePrefKey,
          mode == ThemeMode.dark ? 'dark' : 'light',
        );
      }
    } catch (e) {
      // State vẫn đổi cho phiên này; chỉ mất persist qua restart.
      debugPrint('theme mode save skipped: $e');
    }
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Brightness HIỆU LỰC sau khi cộng lựa chọn user + brightness máy.
final effectiveBrightnessProvider = Provider<Brightness>((ref) {
  final mode = ref.watch(themeModeControllerProvider);
  return switch (mode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => ref.watch(platformBrightnessProvider),
  };
});
