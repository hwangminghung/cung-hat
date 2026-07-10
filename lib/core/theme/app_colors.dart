import 'package:flutter/material.dart';

/// Warm paper, citrus, and ink palette for the retro mixtape interface.
abstract final class AppColors {
  static const primary = Color(0xFFE8501F);
  static const primaryDark = Color(0xFF942D0E);
  static const primaryTint = Color(0xFFF8C9B8);
  static const primarySoft = Color(0xFFF18D69);
  static const onPrimary = Color(0xFFFFFFFF);

  static const secondary = Color(0xFFC6E534);
  static const secondaryDark = Color(0xFF506100);
  static const secondaryTint = Color(0xFFEDF6B7);

  static const teal = Color(0xFF8FD8C8);

  /// Compatibility aliases retained for existing consumers.
  static const tertiary = teal;
  static const cyan = teal;
  static const tertiaryTint = Color(0xFFDDF3EE);
  static const tertiaryPop = Color(0xFF5DBBA8);

  static const pink = Color(0xFFE979A9);

  static const background = Color(0xFFF7EFD8);
  static const surface = Color(0xFFFCF6E3);
  static const surfaceAlt = Color(0xFFEFE4C8);
  static const surfaceWarm = Color(0xFFFADBC7);
  static const surfaceMuted = Color(0xFFE2D6B9);

  static const ink = Color(0xFF1E3A2F);
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF405B50);
  static const textHint = Color(0xFF5C7168);
  static const border = ink;

  static const success = Color(0xFF287A56);
  static const successTint = Color(0xFFDDF1E7);
  static const warning = Color(0xFFA65B00);
  static const warningTint = Color(0xFFFFE8BF);
  static const error = Color(0xFFB42318);
  static const errorTint = Color(0xFFFAD7D3);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primary],
  );

  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const shadow = ink;
}
