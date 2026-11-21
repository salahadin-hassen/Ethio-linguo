import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'animated_count.dart';
import 'brand_icons.dart';

/// Compact stat (streak / XP / hearts) used in headers.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.semanticLabel,
    this.color = AppColors.indigo,
    this.background = AppColors.surface,
    this.muted = false,
  });

  final BrandIconKind icon;
  final int value;
  final String semanticLabel;
  final Color color;
  final Color background;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandIcon(icon, size: 22, muted: muted),
            const SizedBox(width: 6),
            AnimatedCount(
              value: value,
              style: AppType.label.copyWith(color: color, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
