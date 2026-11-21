import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/components/brand_icons.dart';
import '../../../core/components/progress_bar.dart';
import '../../../core/components/speech_bubble.dart';
import '../../../core/components/stat_pill.dart';
import '../../../core/components/tibeb_band.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/progress.dart';
import '../../mascot/mascot.dart';

/// Indigo hero: stats, personalised greeting, mascot and level ring.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  static String _partOfDay(int hour) => hour < 12
      ? 'Good morning'
      : hour < 17
      ? 'Good afternoon'
      : 'Good evening';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.progress;
    final level = app.level;
    final hour = app.now.hour;
    final mood = p.completedNodeIds.isEmpty
        ? MascotMood.welcome
        : app.practicedToday
        ? MascotMood.happy
        : MascotMood.encouraging;
    final message = p.completedNodeIds.isEmpty
        ? 'Your first lesson takes 3 minutes!'
        : app.practicedToday
        ? 'Streak safe today. Keep going?'
        : 'A quick lesson keeps your streak alive.';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.sm,
                Space.gutter,
                0,
              ),
              child: Row(
                children: [
                  StatPill(
                    icon: BrandIconKind.flame,
                    value: app.streak,
                    muted: app.streak == 0,
                    semanticLabel: '${app.streak} day streak',
                    color: AppColors.ivory,
                    background: AppColors.indigoRaised,
                  ),
                  const SizedBox(width: Space.xs),
                  StatPill(
                    icon: BrandIconKind.xp,
                    value: p.totalXp,
                    semanticLabel: '${p.totalXp} XP',
                    color: AppColors.ivory,
                    background: AppColors.indigoRaised,
                  ),
                  const Spacer(),
                  StatPill(
                    icon: BrandIconKind.heart,
                    value: p.hearts,
                    semanticLabel:
                        '${p.hearts} of ${LearnerProgress.maxHearts} hearts',
                    color: AppColors.ivory,
                    background: AppColors.indigoRaised,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.md,
                Space.gutter,
                Space.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${app.native.greeting}! ${_partOfDay(hour)}',
                          style: AppType.headline.copyWith(
                            color: AppColors.ivory,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        SpeechBubble(
                          text: message,
                          tail: BubbleTail.bottomRight,
                          border: false,
                          color: AppColors.indigoRaised,
                          textColor: AppColors.ivory,
                          style: AppType.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        Semantics(
                          label:
                              'Level ${level.level}, ${level.xpIntoLevel} of ${level.xpForLevel} XP to next level',
                          excludeSemantics: true,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'LVL ${level.level}',
                                  style: AppType.caption.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Space.xs),
                              Expanded(
                                child: AppProgressBar(
                                  value: level.fraction,
                                  color: AppColors.gold,
                                  track: AppColors.indigoRaised,
                                  height: 10,
                                ),
                              ),
                              const SizedBox(width: Space.xs),
                              Text(
                                '${level.xpIntoLevel}/${level.xpForLevel}',
                                style: AppType.caption.copyWith(
                                  color: AppColors.onIndigoMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  Mascot(mood: mood, size: 118),
                ],
              ),
            ),
            const TibebBand(height: 10),
          ],
        ),
      ),
    );
  }
}
