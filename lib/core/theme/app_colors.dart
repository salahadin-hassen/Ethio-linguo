import 'package:flutter/material.dart';

/// Centralized colour tokens.
///
/// Brand colours (coral, teal, gold, periwinkle) are used as FILLS and always
/// carry [indigo] text on top (>= 4.4:1 contrast). For coloured TEXT on light
/// surfaces use the `*Ink` variants, which pass WCAG AA (>= 4.5:1) on ivory.
/// See docs/design/DESIGN_SYSTEM.md for the measured contrast table.
abstract final class AppColors {
  // Core brand palette (starting tokens from the brief).
  static const indigo = Color(0xFF242443);
  static const ivory = Color(0xFFFFF8EF);
  static const coral = Color(0xFFFF705B);
  static const teal = Color(0xFF20B8A6);
  static const gold = Color(0xFFF4BD50);
  static const periwinkle = Color(0xFF7183F5);

  // Accessible text variants for use on ivory / white.
  static const coralInk = Color(0xFFC23D2A); // 4.99:1 on ivory
  static const tealInk = Color(0xFF0B6E63); // 5.82:1 on ivory
  static const goldInk = Color(0xFF8A5A00); // 5.62:1 on ivory
  static const periwinkleInk = Color(0xFF4F5FD6); // 5.06:1 on ivory

  // Shades used for 3D "lip" under pressable surfaces.
  static const coralShade = Color(0xFFD9503D);
  static const tealShade = Color(0xFF138E80);
  static const goldShade = Color(0xFFD39A2C);
  static const periwinkleShade = Color(0xFF5263D6);
  static const indigoShade = Color(0xFF14142B);

  // Neutrals.
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF6EDE0);
  static const outline = Color(0xFFEADFCF);
  static const outlineStrong = Color(0xFFD8CBB7);
  static const textPrimary = indigo; // 14.15:1 on ivory
  static const textMuted = Color(0xFF6B6A85); // 4.95:1 on ivory
  static const disabledFill = Color(0xFFE9E1D5);
  static const disabledText = Color(0xFF8C8AA0);

  // Dark surfaces (hero headers, lesson feedback).
  static const indigoRaised = Color(0xFF32325A);
  static const onIndigoMuted = Color(0xFFC9C8E6); // 9.0:1 on indigo

  // Soft tints for backgrounds behind brand elements.
  static const coralTint = Color(0xFFFFE6E1);
  static const tealTint = Color(0xFFDDF5F1);
  static const goldTint = Color(0xFFFDF0D2);
  static const periwinkleTint = Color(0xFFE6E9FE);
}
