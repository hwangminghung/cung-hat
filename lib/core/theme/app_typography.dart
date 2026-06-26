import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Be Vietnam Pro text theme mapped onto Material text styles.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final t = GoogleFonts.beVietnamProTextTheme(base);
    return t.copyWith(
      headlineMedium: t.headlineMedium?.copyWith(
          fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge: t.titleLarge?.copyWith(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: t.titleMedium?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: t.bodyLarge?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium: t.bodyMedium?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodySmall: t.bodySmall?.copyWith(
          fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge: t.labelLarge?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
