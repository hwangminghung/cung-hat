import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/config/app_config.dart';

void main() {
  test('AppConfig reads supabase values from dart-define', () {
    const cfg = AppConfig(supabaseUrl: 'https://x.supabase.co', supabaseAnonKey: 'k');
    expect(cfg.supabaseUrl, 'https://x.supabase.co');
    expect(cfg.supabaseAnonKey, 'k');
    expect(cfg.isConfigured, isTrue);
  });

  test('AppConfig.isConfigured is false when empty', () {
    const cfg = AppConfig(supabaseUrl: '', supabaseAnonKey: '');
    expect(cfg.isConfigured, isFalse);
  });
}
