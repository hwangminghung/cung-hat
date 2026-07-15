import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/config/app_config.dart';
import 'core/providers/supabase_providers.dart';
import 'core/push/push_service.dart';
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
  await Supabase.initialize(url: cfg.supabaseUrl, anonKey: cfg.supabaseAnonKey); // ignore: deprecated_member_use
  unawaited(_initPush(Supabase.instance.client));
  runApp(
    ProviderScope(
      overrides: [supabaseClientProvider.overrideWithValue(Supabase.instance.client)],
      child: const CungHatApp(),
    ),
  );
}

/// Best-effort FCM registration. Fully guarded: missing Firebase config (dev / no
/// google-services.json) or an unsupported platform must never crash startup.
Future<void> _initPush(SupabaseClient client) async {
  try {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final platform = Platform.isIOS ? 'ios' : 'android';
    Future<void> register(String? token) async {
      if (token == null) return;
      if (client.auth.currentSession == null) return; // RPC is authenticated-only
      await PushService(client).registerToken(token, platform);
    }
    await register(await messaging.getToken());
    messaging.onTokenRefresh.listen(register);
  } catch (e) {
    debugPrint('Push init skipped: $e');
  }
}
