import 'package:flutter/material.dart';

import '../../../core/components/brand_icons.dart';
import '../../../core/components/pressable.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Selectable language card. Languages are identified by their own script
/// and name (endonym) — never by a flag alone.
class LanguageOptionCard extends StatelessWidget {
  const LanguageOptionCard({
    super.key,
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String glyph;
  final String title;
  final String subtitle;
  final String caption;
  final Color accent;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return AnimatedScale(
      scale: selected ? 1.0 : 0.985,
      duration: Motion.of(context, Motion.fast),
      child: Pressable(
        onTap: onTap,
        selected: selected,
        semanticLabel: '$title, $subtitle${badge != null ? ', $badge' : ''}',
        color: selected ? AppColors.tealTint : AppColors.surface,
        shade: selected ? AppColors.teal : AppColors.outline,
        border: Border.all(
          color: selected ? AppColors.teal : AppColors.outline,
          width: 2,
        ),
        borderRadius: Radii.lgAll,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: disabled ? 0.55 : 1,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      glyph,
                      style: AppType.headline.copyWith(
                        fontSize: 26,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppType.title),
                        Text(
                          subtitle,
                          style: AppType.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          caption,
                          style: AppType.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSunken,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(badge!, style: AppType.caption),
                    )
                  else
                    AnimatedSwitcher(
                      duration: Motion.of(context, Motion.medium),
                      transitionBuilder: (c, a) => ScaleTransition(
                        scale: CurvedAnimation(parent: a, curve: Motion.bouncy),
                        child: c,
                      ),
                      child: selected
                          ? Container(
                              key: const ValueKey(true),
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: AppColors.teal,
                                shape: BoxShape.circle,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: BrandIcon(BrandIconKind.check),
                              ),
                            )
                          : Container(
                              key: const ValueKey(false),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.outlineStrong,
                                  width: 2,
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
