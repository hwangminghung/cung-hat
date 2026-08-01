import 'package:flutter/material.dart';

/// Deliberately rigid shadows used by retro surfaces and controls.
abstract final class AppShadows {
  static const hardColor = Color(0x331E3A2F);

  static const hard = BoxShadow(
    color: hardColor,
    offset: Offset(3, 3),
    blurRadius: 0,
  );
}
