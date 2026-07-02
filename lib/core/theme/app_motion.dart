import 'package:flutter/animation.dart';

/// Motion tokens — one rhythm across the app.
/// Micro-interactions 150–300ms; exits ~65% of enters; ease-out in, ease-in out.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150); // press, hover, toggles
  static const base = Duration(milliseconds: 220); // fades, chips, cards
  static const slow = Duration(milliseconds: 300); // sheets, page elements
  static const exit = Duration(milliseconds: 140); // dismiss/fade-out

  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
  static const springCurve = Curves.easeOutBack; // celebratory pops

  /// Press scale for tappable cards (keeps layout bounds stable).
  static const pressScale = 0.97;

  /// Stagger step for list/grid item entrances.
  static const staggerStep = Duration(milliseconds: 40);
}
