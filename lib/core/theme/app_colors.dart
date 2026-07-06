import 'package:flutter/material.dart';

/// Stitch-inspired warm Gen Z palette for Cung Hat.
abstract final class AppColors {
  static const primary = Color(0xFFFF6B4A);
  static const primaryDark = Color(0xFFAE3115);
  static const primaryTint = Color(0xFFFFDAD2);
  static const primarySoft = Color(0xFFFFB4A3);
  static const onPrimary = Color(0xFFFFFFFF);

  static const secondary = Color(0xFFC8F252);
  static const secondaryDark = Color(0xFF4F6600);
  static const secondaryTint = Color(0xFFF1FFD0);

  static const tertiary = Color(0xFF674BB5);
  static const tertiaryTint = Color(0xFFE8DDFF);
  static const tertiaryPop = Color(0xFFA488F7);

  static const pink = Color(0xFFF472B6);
  static const cyan = Color(0xFF65D6E8);

  static const background = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF4F3F1);
  static const surfaceWarm = Color(0xFFFFF4EF);
  static const surfaceMuted = Color(0xFFE9E8E5);

  static const textPrimary = Color(0xFF1A1C1A);
  static const textSecondary = Color(0xFF59413C);
  static const textHint = Color(0xFF8D716A);
  static const border = Color(0xFFE1BFB8);

  static const success = Color(0xFF2E9E6B);
  static const successTint = Color(0xFFE4F4EC);
  static const warning = Color(0xFFE8A33D);
  static const warningTint = Color(0xFFFFF2D6);
  static const error = Color(0xFFBA1A1A);
  static const errorTint = Color(0xFFFFDAD6);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, pink],
  );

  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, warning],
  );

  static const shadow = Color(0xFF8C1900);
}
