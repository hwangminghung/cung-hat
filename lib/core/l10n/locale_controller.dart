import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pref key cho locale override ('vi'/'en'); vắng = theo hệ thống.
const kLocaleOverridePrefKey = 'locale_override';

/// Đọc override đã lưu — gọi trong main() TRƯỚC runApp để seed
/// [initialLocaleProvider] (không nháy ngôn ngữ frame đầu). Best-effort:
/// prefs hỏng/thiếu plugin (unit test cũ) → null (theo hệ thống).
Future<Locale?> loadSavedLocaleOverride() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kLocaleOverridePrefKey);
    return code == null ? null : Locale(code);
  } catch (e) {
    debugPrint('locale override load skipped: $e');
    return null;
  }
}

/// Giá trị seed từ main (override trong ProviderScope). null = hệ thống.
final initialLocaleProvider = Provider<Locale?>((_) => null);

/// Nguồn sự thật locale trong app: null = theo hệ thống (rơi vào
/// localeResolutionCallback của MaterialApp), khác null = user tự chọn
/// trong Cài đặt → toàn app rebuild sang ngôn ngữ mới tức thì.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => ref.watch(initialLocaleProvider);

  Future<void> set(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(kLocaleOverridePrefKey);
      } else {
        await prefs.setString(kLocaleOverridePrefKey, locale.languageCode);
      }
    } catch (e) {
      // State vẫn đổi cho phiên này; chỉ mất persist qua restart.
      debugPrint('locale override save skipped: $e');
    }
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
