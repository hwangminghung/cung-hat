import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Condensed Oswald headings paired with readable Be Vietnam Pro copy.
abstract final class AppTypography {
  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.18,
    Color color = AppColors.textPrimary,
  }) => _withPublicFamily(
    GoogleFonts.oswald(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    ),
    'Oswald',
  );

  static TextStyle _withPublicFamily(TextStyle style, String family) {
    final generatedFamily = style.fontFamily;
    return style.copyWith(
      fontFamily: family,
      fontFamilyFallback: <String>[
        ?generatedFamily,
        ...?style.fontFamilyFallback,
      ],
    );
  }

  static TextStyle _oswald(
    TextStyle? base, {
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
  }) => _withPublicFamily(
    GoogleFonts.oswald(
      textStyle: base,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: AppColors.textPrimary,
    ),
    'Oswald',
  );

  static TextStyle _beVietnamPro(
    TextStyle? base, {
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
  }) => _withPublicFamily(
    GoogleFonts.beVietnamPro(
      textStyle: base,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    ),
    'BeVietnamPro',
  );

  static TextTheme textTheme(TextTheme base) => base.copyWith(
    displayLarge: _oswald(
      base.displayLarge,
      fontSize: 44,
      fontWeight: FontWeight.w700,
      height: 1.05,
    ),
    displayMedium: _oswald(
      base.displayMedium,
      fontSize: 38,
      fontWeight: FontWeight.w700,
      height: 1.08,
    ),
    displaySmall: _oswald(
      base.displaySmall,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    headlineLarge: _oswald(
      base.headlineLarge,
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.12,
    ),
    headlineMedium: _oswald(
      base.headlineMedium,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.15,
    ),
    headlineSmall: _oswald(
      base.headlineSmall,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.18,
    ),
    titleLarge: _oswald(
      base.titleLarge,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    titleMedium: _oswald(
      base.titleMedium,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    titleSmall: _oswald(
      base.titleSmall,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    bodyLarge: _beVietnamPro(
      base.bodyLarge,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: _beVietnamPro(
      base.bodyMedium,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    bodySmall: _beVietnamPro(
      base.bodySmall,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.textSecondary,
    ),
    labelLarge: _beVietnamPro(
      base.labelLarge,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    labelMedium: _beVietnamPro(
      base.labelMedium,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.4,
    ),
    labelSmall: _beVietnamPro(
      base.labelSmall,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.3,
    ),
  );
}
