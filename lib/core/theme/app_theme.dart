import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  /// [DARK] light()/dark() dựng từ bảng màu TƯƠNG ỨNG, không đọc
  /// AppColors (bảng đang chọn) — MaterialApp cần cả hai ThemeData cùng lúc.
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryTint,
      onPrimaryContainer: p.primaryDark,
      secondary: p.secondary,
      onSecondary: AppPalette.light.ink,
      secondaryContainer: p.secondaryTint,
      onSecondaryContainer: p.ink,
      tertiary: p.teal,
      onTertiary: AppPalette.light.ink,
      tertiaryContainer: p.tertiaryTint,
      onTertiaryContainer: p.ink,
      surface: p.surface,
      onSurface: p.ink,
      surfaceDim: p.surfaceAlt,
      surfaceBright: p.surface,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceAlt,
      surfaceContainerHighest: p.surfaceMuted,
      onSurfaceVariant: p.textSecondary,
      outline: p.ink,
      outlineVariant: p.ink,
      shadow: p.hardShadow,
      scrim: p.scrim,
      inverseSurface: p.ink,
      onInverseSurface: p.surface,
      inversePrimary: p.primarySoft,
      surfaceTint: Colors.transparent,
      error: p.error,
      onError: p.onPrimary,
      errorContainer: p.errorTint,
      onErrorContainer: p.ink,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = AppTypography.textTheme(base.textTheme, ink: p.ink);
    final ctaTextStyle = textTheme.labelLarge?.copyWith(
      fontSize: 19,
      fontWeight: FontWeight.w700,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
    );
    final buttonSide = WidgetStatePropertyAll(
      BorderSide(color: p.ink, width: 2),
    );

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
      borderSide: BorderSide(color: color, width: 2),
    );

    WidgetStateProperty<Color?> filledBackground() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return p.surfaceMuted;
          }
          if (states.contains(WidgetState.pressed)) {
            // Dark: primaryDark là sắc SÁNG (đào) — nền nút pressed vẫn cần
            // sắc đậm, dùng chung giá trị lịch sử của light.
            return AppPalette.light.primaryDark;
          }
          return p.primary;
        });

    WidgetStateProperty<Color?> filledForeground() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return p.ink;
          }
          return p.onPrimary;
        });

    WidgetStateProperty<Color?> outlineForeground() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return p.textHint;
          }
          return p.primaryDark;
        });

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      shadowColor: p.hardShadow,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: p.ink),
        actionsIconTheme: IconThemeData(color: p.ink),
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: filledBackground(),
          foregroundColor: filledForeground(),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(p.hardShadow),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSpacing.buttonHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          textStyle: WidgetStatePropertyAll(ctaTextStyle),
          side: buttonSide,
          shape: WidgetStatePropertyAll(buttonShape),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: filledBackground(),
          foregroundColor: filledForeground(),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(p.hardShadow),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSpacing.buttonHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          textStyle: WidgetStatePropertyAll(ctaTextStyle),
          side: buttonSide,
          shape: WidgetStatePropertyAll(buttonShape),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface),
          foregroundColor: outlineForeground(),
          overlayColor: WidgetStatePropertyAll(
            p.primaryTint.withValues(alpha: 0.55),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(p.hardShadow),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSpacing.buttonHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          side: buttonSide,
          shape: WidgetStatePropertyAll(buttonShape),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: outlineForeground(),
          overlayColor: WidgetStatePropertyAll(
            p.primaryTint.withValues(alpha: 0.55),
          ),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSpacing.buttonHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          shape: WidgetStatePropertyAll(buttonShape),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: border(p.ink),
        enabledBorder: border(p.ink),
        focusedBorder: border(p.ink),
        disabledBorder: border(p.textHint),
        errorBorder: border(p.error),
        focusedErrorBorder: border(p.error),
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.textSecondary),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(
          color: p.primaryDark,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.textHint),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shadowColor: p.hardShadow,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: p.ink, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.secondary,
        elevation: 0,
        pressElevation: 0,
        side: BorderSide(color: p.ink, width: 2),
        labelStyle: textTheme.labelMedium?.copyWith(color: p.ink),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: p.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.navHeight,
        elevation: 0,
        backgroundColor: p.surface,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? p.primaryDark
                : p.ink,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.primary : p.ink,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        selectedItemColor: p.primaryDark,
        unselectedItemColor: p.ink,
        selectedIconTheme: IconThemeData(color: p.primary, size: 24),
        unselectedIconTheme: IconThemeData(color: p.ink, size: 24),
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          color: p.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(color: p.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: p.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.ink),
        actionTextColor: p.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: p.ink, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
          side: BorderSide(color: p.ink, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: p.ink, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        extendedTextStyle: ctaTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          side: BorderSide(color: p.ink, width: 2),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.ink : p.textHint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.secondary
              : p.surfaceMuted,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.ink),
      ),
      listTileTheme: ListTileThemeData(iconColor: p.primary, textColor: p.ink),
      dividerTheme: DividerThemeData(
        color: p.ink,
        thickness: 2,
        space: AppSpacing.xxl,
      ),
    );
  }
}
