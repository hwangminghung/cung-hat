import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Condensed Oswald headings paired with readable Be Vietnam Pro copy.
abstract final class AppTypography {
  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.18,
    // [DARK] AppColors.* nay là getter theo mode — không còn làm default
    // const được; null = ink của bảng màu đang chọn.
    Color? color,
  }) => _withPublicFamily(
    GoogleFonts.oswald(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color ?? AppColors.textPrimary,
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
    required Color color,
  }) => _withPublicFamily(
    GoogleFonts.oswald(
      textStyle: base,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    ),
    'Oswald',
  );

  static TextStyle _beVietnamPro(
    TextStyle? base, {
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required Color color,
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

  /// [ink]/[muted] truyền từ AppTheme._build theo palette — textTheme của
  /// darkTheme không được đọc bảng màu đang chọn.
  static TextTheme textTheme(TextTheme base, {Color? ink, Color? muted}) {
    final inkC = ink ?? AppColors.textPrimary;
    final mutedC = muted ?? AppColors.textSecondary;
    return _textTheme(base, inkC, mutedC);
  }

  static TextTheme _textTheme(TextTheme base, Color ink, Color muted) =>
      base.copyWith(
        displayLarge: _oswald(
          base.displayLarge,
          fontSize: 44,
          fontWeight: FontWeight.w700,
          height: 1.05,
          color: ink,
        ),
        displayMedium: _oswald(
          base.displayMedium,
          fontSize: 38,
          fontWeight: FontWeight.w700,
          height: 1.08,
          color: ink,
        ),
        displaySmall: _oswald(
          base.displaySmall,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: ink,
        ),
        headlineLarge: _oswald(
          base.headlineLarge,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.12,
          color: ink,
        ),
        headlineMedium: _oswald(
          base.headlineMedium,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.15,
          color: ink,
        ),
        headlineSmall: _oswald(
          base.headlineSmall,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.18,
          color: ink,
        ),
        titleLarge: _oswald(
          base.titleLarge,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: ink,
        ),
        titleMedium: _oswald(
          base.titleMedium,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: ink,
        ),
        titleSmall: _oswald(
          base.titleSmall,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: ink,
        ),
        bodyLarge: _beVietnamPro(
          base.bodyLarge,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: ink,
        ),
        bodyMedium: _beVietnamPro(
          base.bodyMedium,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: ink,
        ),
        bodySmall: _beVietnamPro(
          base.bodySmall,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: muted,
        ),
        labelLarge: _beVietnamPro(
          base.labelLarge,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: ink,
        ),
        labelMedium: _beVietnamPro(
          base.labelMedium,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.3,
          letterSpacing: 0.4,
          color: ink,
        ),
        labelSmall: _beVietnamPro(
          base.labelSmall,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0.3,
          color: ink,
        ),
      );
}
