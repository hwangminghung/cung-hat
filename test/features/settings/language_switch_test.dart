import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cung_hat/core/l10n/locale_controller.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';

class _MockSettingsRepo extends Mock implements SettingsRepository {}

Future<void> _pumpResponsiveSettings(
  WidgetTester tester, {
  required double width,
  required double textScale,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  SharedPreferences.setMockInitialValues({});

  final repo = _MockSettingsRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
        myConsentsProvider.overrideWith(
          (ref) async => const <String, bool>{
            'location': true,
            'photos': true,
            'matching': true,
            'marketing': false,
            'cross_border': true,
          },
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(platform: platform),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectReachable(
  WidgetTester tester,
  Finder target, {
  required String reason,
}) async {
  expect(target, findsOneWidget, reason: reason);
  await tester.dragUntilVisible(
    target,
    find.byType(ListView),
    const Offset(0, -160),
    maxIteration: 30,
  );
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget, reason: reason);
}

Future<void> _verifyResponsiveSettings(
  WidgetTester tester, {
  required double width,
  required double textScale,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await _pumpResponsiveSettings(
    tester,
    width: width,
    textScale: textScale,
    platform: platform,
  );

  for (final key in <Key>[
    const Key('screen_22_settings'),
    const Key('settings_privacy_section'),
    const Key('settings_language_section'),
    const Key('settings_account_section'),
    const Key('settings_legal_section'),
  ]) {
    expect(
      find.byKey(key),
      findsOneWidget,
      reason: '$key missing at ${width}dp, ${textScale}x, $platform',
    );
  }

  final controls = <Finder>[
    find.byKey(const Key('consent_location')),
    find.byKey(const Key('lang_en')),
    find.widgetWithText(ListTile, 'Tải dữ liệu của tôi'),
    find.widgetWithText(ListTile, 'Đăng xuất'),
    find.widgetWithText(ListTile, 'Xóa tài khoản'),
    find.widgetWithText(ListTile, 'Chính sách bảo mật'),
    find.widgetWithText(ListTile, 'Điều khoản'),
  ];
  for (final control in controls) {
    await _expectReachable(
      tester,
      control,
      reason: '$control not reachable at ${width}dp, ${textScale}x, $platform',
    );
  }

  expect(
    tester.takeException(),
    isNull,
    reason: 'Settings overflowed at ${width}dp, ${textScale}x, $platform',
  );
}

void main() {
  testWidgets(
    'chọn English trong Cài đặt → locale override = en; hệ thống → null',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = _MockSettingsRepo();
      when(() => repo.myConsents()).thenAnswer((_) async => {});

      late ProviderContainer container;
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

      expect(find.byKey(const Key('screen_22_settings')), findsOneWidget);
      expect(find.byKey(const Key('settings_privacy_section')), findsOneWidget);
      expect(
        find.byKey(const Key('settings_language_section')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('settings_account_section')), findsOneWidget);
      expect(find.byKey(const Key('settings_legal_section')), findsOneWidget);
      expect(find.text('Ngôn ngữ'), findsOneWidget);
      expect(find.text('Mặc định (Tiếng Việt)'), findsOneWidget);

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
      expect(tester.takeException(), isNull);
    },
  );

  // [LIVE-FIX] Emulator test bắt: khi app EN, tiêu đề mục ngôn ngữ phải là
  // 'Language' (không phải 'Ngôn ngữ') và nhãn consent phải theo l10n EN.
  testWidgets('locale EN → mục Ngôn ngữ hiện "Language" + consent EN', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _MockSettingsRepo();
    when(() => repo.myConsents()).thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsNothing);
    // Nhãn consent 'location' theo l10n EN, không còn hardcode VI.
    expect(find.text('Dùng vị trí để gợi ý người/kèo gần bạn'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in <double>[360, 393, 430]) {
    for (final textScale in <double>[1, 1.2, 1.4]) {
      testWidgets(
        'Settings stays reachable at ${width}dp and ${textScale}x text',
        (tester) => _verifyResponsiveSettings(
          tester,
          width: width,
          textScale: textScale,
        ),
      );
    }
  }

  testWidgets('Settings renders its full hierarchy on iOS at 393dp and 1.4x', (
    tester,
  ) {
    return _verifyResponsiveSettings(
      tester,
      width: 393,
      textScale: 1.4,
      platform: TargetPlatform.iOS,
    );
  });
}
