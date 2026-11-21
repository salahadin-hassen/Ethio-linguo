import 'package:flutter/material.dart';

import '../../../core/components/progress_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/course.dart';

class UnitHeader extends StatelessWidget {
  const UnitHeader({
    super.key,
    required this.unit,
    required this.progress,
    required this.locked,
  });

  final Unit unit;
  final double progress;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = locked ? AppColors.disabledFill : unit.color;
    return Semantics(
      header: true,
      label:
          'Unit ${unit.number}, ${unit.title}. ${locked ? 'Locked' : '${(progress * 100).round()}% complete'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: locked ? AppColors.outlineStrong : unit.shade,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNIT ${unit.number}',
                    style: AppType.overline.copyWith(
                      color: locked ? AppColors.textMuted : AppColors.indigo,
                    ),
                  ),
                  Text(
                    unit.title,
                    style: AppType.headline.copyWith(
                      color: locked ? AppColors.textMuted : AppColors.indigo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locked
                        ? 'Finish Unit ${unit.number - 1} to unlock'
                        : unit.subtitle,
                    style: AppType.bodySmall.copyWith(
                      color: locked ? AppColors.textMuted : AppColors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            ProgressRing(
              value: progress,
              size: 58,
              color: locked ? AppColors.outlineStrong : AppColors.indigo,
              track: Colors.white.withValues(alpha: 0.45),
              child: Text(
                '${(progress * 100).round()}%',
                style: AppType.caption.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
