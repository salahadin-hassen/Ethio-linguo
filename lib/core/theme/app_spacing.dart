import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 4-pt spacing scale.
abstract final class Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Horizontal page gutter.
  static const gutter = 20.0;
}

abstract final class Radii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
}

abstract final class Shadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.indigo.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get lifted => [
    BoxShadow(
      color: AppColors.indigo.withValues(alpha: 0.12),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}
