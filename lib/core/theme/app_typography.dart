import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens.
///
/// Nunito handles Latin (English, Afaan Oromo). Ethiopic characters are not in
/// Nunito, so every style declares Noto Sans Ethiopic as a fallback — Amharic
/// renders from bundled glyphs, never from device fonts. Line heights are a
/// little generous (>=1.3) because Ethiopic glyphs are taller than Latin x-height,
/// and leading is distributed evenly so mixed-script lines don't clip.
abstract final class AppType {
  static const family = 'Nunito';
  static const fallback = ['NotoSansEthiopic'];

  static TextStyle _base(
    double size,
    FontWeight weight,
    double height, {
    double spacing = 0,
  }) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
    leadingDistribution: TextLeadingDistribution.even,
    color: AppColors.textPrimary,
  );

  static final display = _base(34, FontWeight.w900, 1.15, spacing: -0.5);
  static final headline = _base(26, FontWeight.w900, 1.2, spacing: -0.3);
  static final title = _base(20, FontWeight.w800, 1.3);
  static final titleSmall = _base(17, FontWeight.w800, 1.3);
  static final body = _base(16, FontWeight.w600, 1.45);
  static final bodySmall = _base(14, FontWeight.w600, 1.4);
  static final label = _base(15, FontWeight.w800, 1.3, spacing: 0.2);
  static final caption = _base(12.5, FontWeight.w700, 1.35, spacing: 0.3);
  static final overline = _base(12, FontWeight.w900, 1.3, spacing: 1.2);

  /// Large prompt text used for words being learned (often Ethiopic).
  static final prompt = _base(28, FontWeight.w800, 1.4);

  static TextTheme get textTheme => TextTheme(
    displaySmall: display,
    headlineMedium: headline,
    titleLarge: title,
    titleMedium: titleSmall,
    bodyLarge: body,
    bodyMedium: bodySmall,
    labelLarge: label,
    bodySmall: caption,
    labelSmall: overline,
  );
}
