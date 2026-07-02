import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Quicksand display + Inter body, matching the Stitch export.
abstract final class AppTypography {
  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.18,
    Color color = AppColors.textPrimary,
  }) => GoogleFonts.quicksand(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
  );

  static TextTheme textTheme(TextTheme base) {
    final t = GoogleFonts.interTextTheme(base);
    return t.copyWith(
      displayLarge: display(fontSize: 40, height: 1.12),
      headlineLarge: display(fontSize: 32, height: 1.15),
      headlineMedium: display(fontSize: 28, height: 1.2),
      headlineSmall: display(fontSize: 22, height: 1.22),
      titleLarge: display(fontSize: 22, height: 1.25),
      titleMedium: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      titleSmall: t.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.textPrimary,
      ),
      bodyLarge: t.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textPrimary,
      ),
      bodyMedium: t.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.42,
        color: AppColors.textPrimary,
      ),
      bodySmall: t.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AppColors.textSecondary,
      ),
      labelLarge: t.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      labelMedium: t.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: 0.6,
      ),
    );
  }
}
