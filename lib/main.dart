import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/providers/supabase_providers.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cfg = AppConfig.fromEnv();
  await Supabase.initialize(url: cfg.supabaseUrl, anonKey: cfg.supabaseAnonKey); // ignore: deprecated_member_use
  runApp(
    ProviderScope(
      overrides: [supabaseClientProvider.overrideWithValue(Supabase.instance.client)],
      child: const CungHatApp(),
    ),
  );
}
