import 'package:flutter/material.dart';

/// Coral warm palette — single source of color truth (light mode).
abstract final class AppColors {
  static const primary = Color(0xFFE05732);
  static const primaryDark = Color(0xFFC2451F); // pressed state
  static const primaryTint = Color(0xFFFCE9E2); // selected fills, soft accents
  static const onPrimary = Color(0xFFFFFFFF);

  static const background = Color(0xFFFBF6F3); // warm off-white page bg
  static const surface = Color(0xFFFFFFFF); // cards, inputs

  static const textPrimary = Color(0xFF2A1D18);
  static const textSecondary = Color(0xFF7A6A63);
  static const textHint = Color(0xFFA89A93);
  static const border = Color(0xFFF0E6E0);

  static const success = Color(0xFF2E9E6B);
  static const warning = Color(0xFFE8A33D);
  static const error = Color(0xFFD64545);
}
