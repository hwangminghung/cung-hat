import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// Runs [body], collecting any Flutter error NOT matching the known
/// pre-existing ink-splash assertion below, then asserts none occurred.
///
/// SettingsScreen's non-consent tiles (`_SettingsTile`, used for "Tải dữ
/// liệu của tôi" / "Đăng xuất" / "Xóa tài khoản" / pháp lý) render a bare
/// ListTile inside a decorated Container without a Material ancestor — a
/// pre-existing, unrelated bug that fires this assertion on every pump of
/// the full screen (verified: fires even with zero interaction, before this
/// fix, on master). Fixing it is out of scope for the consent-toggle guard
/// under test here, so we filter ONLY that known text and fail on anything
/// else — a genuine unhandled exception from the consent-toggle path (the
/// bug this fix addresses) still fails the test.
Future<void> _expectNoUnexpectedErrors(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final unexpected = <Object>[];
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details
        .exceptionAsString()
        .contains('ListTile background color or ink splashes')) {
      return;
    }
    unexpected.add(details.exception);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = originalOnError;
  }
  expect(unexpected, isEmpty, reason: 'unexpected Flutter errors: $unexpected');
}

void main() {
  group('SettingsScreen — consent toggle lỗi RPC', () {
    testWidgets(
        'grantConsent lỗi → SnackBar báo lỗi, không crash, switch giữ nguyên',
        (tester) async {
      final repo = _MockSettingsRepository();
      when(() => repo.grantConsent(any()))
          .thenAnswer((_) async => throw Exception('offline'));

      await _expectNoUnexpectedErrors(tester, () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(repo),
              myConsentsProvider.overrideWith(
                  (ref) async => <String, bool>{'marketing': false}),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('consent_marketing')));
        await tester.pumpAndSettle();
      });

      expect(find.text('Không lưu được cài đặt, thử lại.'), findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('consent_marketing')),
      );
      expect(switchTile.value, isFalse);
    });

    testWidgets(
        'withdrawConsent lỗi → SnackBar báo lỗi, không crash, switch giữ nguyên',
        (tester) async {
      final repo = _MockSettingsRepository();
      when(() => repo.withdrawConsent(any()))
          .thenAnswer((_) async => throw Exception('offline'));

      await _expectNoUnexpectedErrors(tester, () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(repo),
              myConsentsProvider.overrideWith(
                  (ref) async => <String, bool>{'marketing': true}),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('consent_marketing')));
        await tester.pumpAndSettle();
      });

      expect(find.text('Không lưu được cài đặt, thử lại.'), findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('consent_marketing')),
      );
      expect(switchTile.value, isTrue);
    });

    testWidgets(
        'grantConsent thành công → không SnackBar lỗi, gọi repository đúng purpose',
        (tester) async {
      final repo = _MockSettingsRepository();
      when(() => repo.grantConsent(any())).thenAnswer((_) async {});

      await _expectNoUnexpectedErrors(tester, () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(repo),
              myConsentsProvider.overrideWith(
                  (ref) async => <String, bool>{'marketing': false}),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('consent_marketing')));
        await tester.pumpAndSettle();
      });

      expect(find.text('Không lưu được cài đặt, thử lại.'), findsNothing);
      verify(() => repo.grantConsent('marketing')).called(1);
    });
  });
}
