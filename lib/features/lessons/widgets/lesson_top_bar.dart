import 'package:flutter/material.dart';

import '../../../core/components/animated_count.dart';
import '../../../core/components/brand_icons.dart';
import '../../../core/components/progress_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class LessonTopBar extends StatelessWidget {
  const LessonTopBar({
    super.key,
    required this.progress,
    required this.hearts,
    required this.onClose,
    required this.practiceMode,
  });

  final double progress;
  final int hearts;
  final bool practiceMode;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('close_lesson'),
            tooltip: 'Quit lesson',
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              size: 30,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: AppProgressBar(
              value: progress,
              height: 16,
              semanticLabel: 'Lesson progress',
            ),
          ),
          const SizedBox(width: 14),
          Semantics(
            label: practiceMode
                ? 'Practice mode, no hearts left'
                : '$hearts hearts left',
            excludeSemantics: true,
            child: Row(
              children: [
                BrandIcon(BrandIconKind.heart, size: 26, muted: hearts == 0),
                const SizedBox(width: 4),
                AnimatedCount(
                  value: hearts,
                  style: AppType.label.copyWith(
                    color: hearts == 0
                        ? AppColors.textMuted
                        : AppColors.coralInk,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
