import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/brand_icons.dart';
import '../../../core/components/progress_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/gamification.dart';

class DailyQuestsCard extends StatelessWidget {
  const DailyQuestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final quests = AppScope.of(context).quests;
    final done = quests.where((q) => q.done).length;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Daily quests', style: AppType.title),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$done/${quests.length} done',
                  style: AppType.caption.copyWith(color: AppColors.goldInk),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          for (final q in quests) _QuestRow(quest: q),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest});
  final DailyQuest quest;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (quest.kind) {
      QuestKind.earnXp => (BrandIconKind.xp, AppColors.periwinkle),
      QuestKind.completeLessons => (BrandIconKind.star, AppColors.gold),
      QuestKind.perfectLesson => (BrandIconKind.gem, AppColors.teal),
    };
    return Semantics(
      label:
          '${quest.title}: ${quest.progress.clamp(0, quest.goal)} of ${quest.goal}${quest.done ? ', complete' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: BrandIcon(icon),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quest.title, style: AppType.label),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: AppProgressBar(
                          value: quest.fraction,
                          color: color,
                          height: 12,
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${quest.progress.clamp(0, quest.goal)}/${quest.goal}',
                          textAlign: TextAlign.end,
                          style: AppType.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            AnimatedOpacity(
              opacity: quest.done ? 1 : 0.35,
              duration: const Duration(milliseconds: 300),
              child: BrandIcon(
                BrandIconKind.crown,
                size: 26,
                muted: !quest.done,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
