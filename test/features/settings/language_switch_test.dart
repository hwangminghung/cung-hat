import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cung_hat/core/l10n/locale_controller.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';

class _MockSettingsRepo extends Mock implements SettingsRepository {}

/// Cùng filter với settings_toggle_error_test.dart: lọc DUY NHẤT assertion
/// ink-splash có sẵn (SwitchListTile consent trong Container màu của
/// _Section); mọi exception khác vẫn làm test fail.
Future<void> _expectNoUnexpectedErrors(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final unexpected = <Object>[];
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains(
      'ListTile background color or ink splashes',
    )) {
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
  testWidgets(
      'chọn English trong Cài đặt → locale override = en; hệ thống → null',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _MockSettingsRepo();
    when(() => repo.myConsents()).thenAnswer((_) async => {});

    late ProviderContainer container;
    await _expectNoUnexpectedErrors(tester, () async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(home: SettingsScreen());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ngôn ngữ'), findsOneWidget);
      expect(find.text('Theo hệ thống'), findsOneWidget);

      await tester.dragUntilVisible(
        find.byKey(const Key('lang_en')),
        find.byType(ListView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.byKey(const Key('lang_en')));
      await tester.pumpAndSettle();
      expect(container.read(localeControllerProvider), const Locale('en'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kLocaleOverridePrefKey), 'en');

      await tester.dragUntilVisible(
        find.byKey(const Key('lang_system')),
        find.byType(ListView),
        const Offset(0, 120),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lang_system')));
      await tester.pumpAndSettle();
      expect(container.read(localeControllerProvider), isNull);
    });
  });
}
