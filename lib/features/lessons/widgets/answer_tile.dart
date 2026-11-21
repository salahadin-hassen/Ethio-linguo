import 'package:flutter/material.dart';

import '../../../core/components/pressable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

enum TileTone { idle, selected, correct, wrong, disabled }

/// Tappable answer surface shared by all exercise types.
class AnswerTile extends StatelessWidget {
  const AnswerTile({
    super.key,
    required this.label,
    required this.tone,
    required this.onTap,
    this.leading,
    this.compact = false,
    this.semanticLabel,
  });

  final String label;
  final TileTone tone;
  final VoidCallback? onTap;
  final String? leading;
  final bool compact;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color edge, Color fg) = switch (tone) {
      TileTone.idle => (AppColors.surface, AppColors.outline, AppColors.indigo),
      TileTone.selected => (
        AppColors.periwinkleTint,
        AppColors.periwinkle,
        AppColors.indigo,
      ),
      TileTone.correct => (
        AppColors.tealTint,
        AppColors.teal,
        AppColors.tealInk,
      ),
      TileTone.wrong => (
        AppColors.coralTint,
        AppColors.coral,
        AppColors.coralInk,
      ),
      TileTone.disabled => (
        AppColors.surfaceSunken,
        AppColors.outline,
        AppColors.disabledText,
      ),
    };
    return Pressable(
      onTap: onTap,
      color: fill,
      shade: edge,
      depth: tone == TileTone.disabled ? 0 : 4,
      selected: tone == TileTone.selected,
      semanticLabel: semanticLabel ?? label,
      border: Border.all(color: edge, width: 2),
      borderRadius: BorderRadius.circular(16),
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 9 : 14,
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (leading != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: edge, width: 2),
                  ),
                  child: Text(
                    leading!,
                    style: AppType.caption.copyWith(color: fg),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  label,
                  style: (compact ? AppType.label : AppType.titleSmall)
                      .copyWith(color: fg, fontSize: compact ? 17 : 19),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
