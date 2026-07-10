import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.ink,
      secondaryContainer: AppColors.secondaryTint,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.teal,
      onTertiary: AppColors.ink,
      tertiaryContainer: AppColors.tertiaryTint,
      onTertiaryContainer: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceDim: AppColors.surfaceAlt,
      surfaceBright: AppColors.surface,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceAlt,
      surfaceContainerHighest: AppColors.surfaceMuted,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      shadow: AppShadows.hardColor,
      scrim: Color(0x991E3A2F),
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.primarySoft,
      surfaceTint: Colors.transparent,
      error: AppColors.error,
      onError: AppColors.onPrimary,
      errorContainer: AppColors.errorTint,
      onErrorContainer: AppColors.ink,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = AppTypography.textTheme(base.textTheme);
    final ctaTextStyle = textTheme.labelLarge?.copyWith(
      fontSize: 19,
      fontWeight: FontWeight.w700,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
    );
    const buttonSide = WidgetStatePropertyAll(
      BorderSide(color: AppColors.border, width: 2),
    );

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
      borderSide: BorderSide(color: color, width: 2),
    );

    WidgetStateProperty<Color?> filledBackground() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceMuted;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primaryDark;
          }
          return AppColors.primary;
        });

    WidgetStateProperty<Color?> filledForeground() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.ink;
          }
          return AppColors.onPrimary;
        });

    WidgetStateProperty<Color?> outlineForeground() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textHint;
          }
          return AppColors.primaryDark;
        });

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      shadowColor: AppShadows.hard.color,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ink),
        actionsIconTheme: const IconThemeData(color: AppColors.ink),
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: filledBackground(),
          foregroundColor: filledForeground(),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(AppShadows.hardColor),
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
          shadowColor: const WidgetStatePropertyAll(AppShadows.hardColor),
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
          backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
          foregroundColor: outlineForeground(),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primaryTint.withValues(alpha: 0.55),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(AppShadows.hardColor),
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
            AppColors.primaryTint.withValues(alpha: 0.55),
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
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.border),
        disabledBorder: border(AppColors.textHint),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.primaryDark,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppShadows.hardColor,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.secondary,
        elevation: 0,
        pressElevation: 0,
        side: const BorderSide(color: AppColors.border, width: 2),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.ink,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.navHeight,
        elevation: 0,
        backgroundColor: AppColors.surface,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryDark
                : AppColors.ink,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.ink,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.ink,
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.ink,
          size: 24,
        ),
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(
          color: AppColors.ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: AppColors.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
        actionTextColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
          side: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.textHint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.secondary
              : AppColors.surfaceMuted,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.border),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 2,
        space: AppSpacing.xxl,
      ),
    );
  }
}
