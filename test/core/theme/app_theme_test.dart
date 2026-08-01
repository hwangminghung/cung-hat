import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_shadows.dart';
import 'package:cung_hat/core/theme/app_spacing.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retro palette exposes the approved literals and aliases', () {
    expect(AppColors.background, const Color(0xFFF7EFD8));
    expect(AppColors.surface, const Color(0xFFFCF6E3));
    expect(AppColors.ink, const Color(0xFF1E3A2F));
    expect(AppColors.textPrimary, AppColors.ink);
    expect(AppColors.border, AppColors.ink);
    expect(AppColors.shadow, AppColors.ink);
    expect(AppColors.primary, const Color(0xFFE8501F));
    expect(AppColors.secondary, const Color(0xFFC6E534));
    expect(AppColors.teal, const Color(0xFF8FD8C8));
    expect(AppColors.tertiary, AppColors.teal);
    expect(AppColors.cyan, AppColors.teal);
    expect(AppColors.brandGradient.colors, <Color>[
      AppColors.primary,
      AppColors.primary,
    ]);
  });

  test('retro geometry tokens use 14px corners and 52px buttons', () {
    expect(AppSpacing.radiusInput, 14);
    expect(AppSpacing.radiusButton, 14);
    expect(AppSpacing.radiusCard, 14);
    expect(AppSpacing.radiusSheet, 14);
    expect(AppSpacing.radiusPill, 999);
    expect(AppSpacing.buttonHeight, 52);
  });

  test('hard shadow has an exact offset with no blur', () {
    expect(AppShadows.hard.color, const Color(0x331E3A2F));
    expect(AppShadows.hard.offset, const Offset(3, 3));
    expect(AppShadows.hard.blurRadius, 0);
    expect(AppShadows.hard.spreadRadius, 0);
  });

  test('AppTheme.light uses the retro light color scheme', () {
    final theme = AppTheme.light();

    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.secondary, AppColors.secondary);
    expect(theme.colorScheme.tertiary, AppColors.teal);
    expect(theme.colorScheme.onSecondary, AppColors.ink);
    expect(theme.colorScheme.onTertiary, AppColors.ink);
    expect(theme.colorScheme.outlineVariant, AppColors.border);
    expect(theme.colorScheme.shadow, AppShadows.hard.color);
    expect(theme.colorScheme.surfaceTint, Colors.transparent);
    expect(theme.shadowColor, AppShadows.hard.color);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });

  test('every Material text category uses the intended font family', () {
    final textTheme = AppTheme.light().textTheme;
    final oswaldStyles = <TextStyle?>[
      textTheme.displayLarge,
      textTheme.displayMedium,
      textTheme.displaySmall,
      textTheme.headlineLarge,
      textTheme.headlineMedium,
      textTheme.headlineSmall,
      textTheme.titleLarge,
      textTheme.titleMedium,
      textTheme.titleSmall,
    ];
    final beVietnamProStyles = <TextStyle?>[
      textTheme.bodyLarge,
      textTheme.bodyMedium,
      textTheme.bodySmall,
      textTheme.labelLarge,
      textTheme.labelMedium,
      textTheme.labelSmall,
    ];

    for (final style in oswaldStyles) {
      expect(style?.fontFamily, 'Oswald');
    }
    for (final style in beVietnamProStyles) {
      expect(style?.fontFamily, 'BeVietnamPro');
    }
    expect(AppTypography.display().fontFamily, 'Oswald');
    expect(textTheme.labelLarge?.fontSize, greaterThanOrEqualTo(16));
    expect(textTheme.labelLarge?.fontWeight, FontWeight.w700);
  });

  test('all button themes use exact retro geometry and zero elevation', () {
    final theme = AppTheme.light();
    final borderedStyles = <ButtonStyle?>[
      theme.filledButtonTheme.style,
      theme.elevatedButtonTheme.style,
      theme.outlinedButtonTheme.style,
    ];
    final styles = <ButtonStyle?>[
      ...borderedStyles,
      theme.textButtonTheme.style,
    ];

    for (final style in styles) {
      expect(
        style?.minimumSize?.resolve(const <WidgetState>{}),
        const Size(0, 52),
      );
      expect(style?.elevation?.resolve(const <WidgetState>{}), 0);
      final shape =
          style?.shape?.resolve(const <WidgetState>{})
              as RoundedRectangleBorder?;
      expect(shape?.borderRadius, BorderRadius.circular(14));
    }
    for (final style in borderedStyles) {
      expect(style?.side?.resolve(const <WidgetState>{})?.width, 2);
      expect(
        style?.side?.resolve(const <WidgetState>{})?.color,
        AppColors.border,
      );
      expect(
        style?.shadowColor?.resolve(const <WidgetState>{}),
        AppShadows.hard.color,
      );
    }

    const disabled = <WidgetState>{WidgetState.disabled};
    const enabled = <WidgetState>{};
    const pressed = <WidgetState>{WidgetState.pressed};
    expect(
      theme.filledButtonTheme.style?.foregroundColor?.resolve(disabled),
      AppColors.ink,
    );
    expect(
      theme.elevatedButtonTheme.style?.foregroundColor?.resolve(disabled),
      AppColors.ink,
    );
    expect(
      theme.outlinedButtonTheme.style?.backgroundColor?.resolve(
        const <WidgetState>{},
      ),
      AppColors.surface,
    );
    for (final style in <ButtonStyle?>[
      theme.filledButtonTheme.style,
      theme.elevatedButtonTheme.style,
    ]) {
      expect(style?.backgroundColor?.resolve(enabled), AppColors.primary);
      expect(style?.foregroundColor?.resolve(enabled), AppColors.onPrimary);
      expect(style?.textStyle?.resolve(enabled)?.fontSize, 19);
      expect(style?.textStyle?.resolve(enabled)?.fontWeight, FontWeight.w700);
    }
    expect(
      theme.outlinedButtonTheme.style?.foregroundColor?.resolve(pressed),
      AppColors.primaryDark,
    );
    expect(
      theme.textButtonTheme.style?.foregroundColor?.resolve(pressed),
      AppColors.primaryDark,
    );
  });

  test('inputs and cards use 14px corners with 2px borders', () {
    final theme = AppTheme.light();
    final enabled =
        theme.inputDecorationTheme.enabledBorder as OutlineInputBorder;
    final focused =
        theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
    final card = theme.cardTheme.shape as RoundedRectangleBorder;

    expect(enabled.borderRadius, BorderRadius.circular(14));
    expect(enabled.borderSide.width, 2);
    expect(enabled.borderSide.color, AppColors.border);
    expect(focused.borderRadius, BorderRadius.circular(14));
    expect(focused.borderSide.width, 2);
    expect(focused.borderSide.color, AppColors.border);
    expect(card.borderRadius, BorderRadius.circular(14));
    expect(card.side.width, 2);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.cardTheme.shadowColor, AppShadows.hard.color);
  });

  test('retro surface components share 14px geometry and 2px borders', () {
    final theme = AppTheme.light();
    final chip = theme.chipTheme.shape as RoundedRectangleBorder;
    final sheet = theme.bottomSheetTheme.shape as RoundedRectangleBorder;
    final dialog = theme.dialogTheme.shape as RoundedRectangleBorder;
    final snackBar = theme.snackBarTheme.shape as RoundedRectangleBorder;

    expect(chip.borderRadius, BorderRadius.circular(14));
    expect(theme.chipTheme.side?.width, 2);
    expect(
      sheet.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(14)),
    );
    expect(sheet.side.width, 2);
    expect(dialog.borderRadius, BorderRadius.circular(14));
    expect(dialog.side.width, 2);
    expect(snackBar.borderRadius, BorderRadius.circular(14));
    expect(snackBar.side.width, 2);
    expect(snackBar.side.color, AppColors.border);
    expect(theme.snackBarTheme.backgroundColor, AppColors.surface);
    expect(theme.snackBarTheme.contentTextStyle?.color, AppColors.ink);
    expect(theme.bottomSheetTheme.elevation, 0);
    expect(theme.dialogTheme.elevation, 0);
  });

  test('NavigationBar stays flat, transparent, and orange when selected', () {
    final navigation = AppTheme.light().navigationBarTheme;
    const selected = <WidgetState>{WidgetState.selected};
    const unselected = <WidgetState>{};

    expect(navigation.backgroundColor, AppColors.surface);
    expect(navigation.elevation, 0);
    expect(navigation.indicatorColor, Colors.transparent);
    expect(navigation.iconTheme?.resolve(selected)?.color, AppColors.primary);
    expect(
      navigation.labelTextStyle?.resolve(selected)?.color,
      AppColors.primaryDark,
    );
    expect(
      navigation.labelTextStyle?.resolve(selected)?.fontFamily,
      'BeVietnamPro',
    );
    expect(navigation.iconTheme?.resolve(unselected)?.color, AppColors.ink);
    expect(
      navigation.labelTextStyle?.resolve(unselected)?.color,
      AppColors.ink,
    );
  });

  test('legacy BottomNavigationBar receives the same retro palette', () {
    final navigation = AppTheme.light().bottomNavigationBarTheme;

    expect(navigation.backgroundColor, AppColors.surface);
    expect(navigation.elevation, 0);
    expect(navigation.type, isNull);
    expect(navigation.selectedItemColor, AppColors.primaryDark);
    expect(navigation.unselectedItemColor, AppColors.ink);
    expect(navigation.selectedIconTheme?.color, AppColors.primary);
    expect(navigation.unselectedIconTheme?.color, AppColors.ink);
    expect(navigation.selectedLabelStyle?.fontFamily, 'BeVietnamPro');
    expect(navigation.unselectedLabelStyle?.fontFamily, 'BeVietnamPro');
  });

  test(
    'required Google Fonts weights are bundled under recognized names',
    () async {
      const expectedAssets = <String, int>{
        'google_fonts/BeVietnamPro-Regular.ttf': 72288,
        'google_fonts/BeVietnamPro-Medium.ttf': 72424,
        'google_fonts/BeVietnamPro-SemiBold.ttf': 72268,
        'google_fonts/BeVietnamPro-Bold.ttf': 72172,
        'google_fonts/Oswald-SemiBold.ttf': 86420,
        'google_fonts/Oswald-Bold.ttf': 86392,
      };

      for (final MapEntry(key: path, value: length) in expectedAssets.entries) {
        final font = await rootBundle.load(path);
        expect(font.lengthInBytes, length, reason: path);
      }
    },
  );
}
