import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/app_config.dart';
import 'core/l10n/locale_controller.dart';
import 'core/providers/supabase_providers.dart';
import 'core/theme/theme_mode_controller.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cfg = AppConfig.fromEnv();
  // [AUDIT L3] Thiếu dart-define thì Supabase.initialize nổ FormatException
  // khó hiểu — assert sớm với message chỉ thẳng cách chạy đúng (debug-only).
  assert(
    cfg.isConfigured,
    'Thiếu SUPABASE_URL/SUPABASE_ANON_KEY — chạy với '
    '--dart-define-from-file=env/dev.json (hoặc env/dev.emulator.json).',
  );
  await Supabase.initialize(
    url: cfg.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: cfg.supabaseAnonKey,
  );
  // [LANG] Đọc ngôn ngữ user đã chọn TRƯỚC runApp — không nháy frame đầu.
  final savedLocale = await loadSavedLocaleOverride();
  // [DARK] Cùng lý do với ngôn ngữ: seed theme đã lưu trước frame đầu.
  final savedThemeMode = await loadSavedThemeMode();
  unawaited(_initFirebase());
  runApp(
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(Supabase.instance.client),
        initialLocaleProvider.overrideWithValue(savedLocale),
        initialThemeModeProvider.overrideWithValue(savedThemeMode),
      ],
      child: const CungHatApp(),
    ),
  );
}

/// Chỉ khởi tạo Firebase. Fully guarded: thiếu cấu hình Firebase (dev / không
/// có google-services.json) hoặc nền tảng không hỗ trợ đều không được crash
/// lúc mở app.
///
/// [AUDIT P1-3] Xin quyền thông báo và đăng ký token ĐÃ CHUYỂN sang
/// [pushRegistrationProvider]: chạy khi user có hồ sơ (đã đăng nhập + qua
/// onboarding). Ở đây thì chưa có session — token bị bỏ im lặng và không bao
/// giờ được đăng ký lại, còn hộp thoại xin quyền thì bật lên trước cả màn đăng
/// nhập.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }
}
