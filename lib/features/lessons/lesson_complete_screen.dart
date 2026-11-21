import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/components/animated_count.dart';
import '../../core/components/app_button.dart';
import '../../core/components/brand_icons.dart';
import '../../core/components/confetti.dart';
import '../../core/components/entrance.dart';
import '../../core/components/progress_bar.dart';
import '../../core/components/tibeb_band.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../mascot/mascot.dart';

class LessonCompleteScreen extends StatelessWidget {
  const LessonCompleteScreen({super.key, required this.reward});

  final LessonReward reward;

  @override
  Widget build(BuildContext context) {
    final r = reward.result;
    final app = AppScope.of(context);
    final accuracy = (r.accuracy * 100).round();
    final planted = [
      for (final id in reward.plantedWords) app.course.terms[id]?.english ?? id,
    ];
    final title = r.perfect ? 'Flawless lesson!' : 'Lesson complete!';
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      Space.lg,
                      Space.gutter,
                      Space.lg,
                    ),
                    child: Column(
                      children: [
                        Mascot(
                          mood:
                              reward.newAchievements.isNotEmpty ||
                                  reward.leveledUp
                              ? MascotMood.excited
                              : MascotMood.celebrating,
                          size: 190,
                          reactOnMount: true,
                        ),
                        const SizedBox(height: Space.sm),
                        Entrance(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppType.display.copyWith(
                                color: AppColors.goldInk,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Entrance(
                          delay: const Duration(milliseconds: 80),
                          child: Text(
                            r.perfect
                                ? 'No mistakes — your words are blooming.'
                                : 'Every mistake you fixed made your memory stronger.',
                            textAlign: TextAlign.center,
                            style: AppType.body.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: Space.xl),
                        Entrance(
                          delay: const Duration(milliseconds: 160),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  key: const ValueKey('xp_tile'),
                                  label: 'XP earned',
                                  color: AppColors.gold,
                                  icon: BrandIconKind.xp,
                                  semantic: '${reward.xpEarned} XP earned',
                                  child: AnimatedCount(
                                    from: 0,
                                    value: reward.xpEarned,
                                    prefix: '+',
                                    style: AppType.headline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Space.sm),
                              Expanded(
                                child: _StatTile(
                                  label: 'Accuracy',
                                  color: AppColors.teal,
                                  icon: BrandIconKind.gem,
                                  suffix: '%',
                                  semantic:
                                      '$accuracy percent accuracy, ${r.correctFirstTry} of ${r.totalExercises} correct first try',
                                  child: AnimatedCount(
                                    from: 0,
                                    value: accuracy,
                                    style: AppType.headline,
                                    prefix: '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: Space.sm),
                              Expanded(
                                child: _StatTile(
                                  label: 'Streak',
                                  color: AppColors.coral,
                                  icon: BrandIconKind.flame,
                                  semantic: '${reward.streakAfter} day streak',
                                  child: AnimatedCount(
                                    from: reward.streakBefore,
                                    value: reward.streakAfter,
                                    style: AppType.headline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Space.sm),
                        Text(
                          '${r.correctFirstTry} of ${r.totalExercises} correct on the first try',
                          style: AppType.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: Space.lg),
                        Entrance(
                          delay: const Duration(milliseconds: 260),
                          child: _ProgressCard(reward: reward),
                        ),
                        if (planted.isNotEmpty) ...[
                          const SizedBox(height: Space.md),
                          Entrance(
                            delay: const Duration(milliseconds: 340),
                            child: _InfoCard(
                              color: AppColors.tealTint,
                              icon: BrandIconKind.leaf,
                              title:
                                  '${planted.length} new words planted in your Word Garden',
                              body: planted.join(' · '),
                            ),
                          ),
                        ],
                        for (final a in reward.newAchievements) ...[
                          const SizedBox(height: Space.md),
                          Entrance(
                            delay: const Duration(milliseconds: 420),
                            child: _InfoCard(
                              color: AppColors.goldTint,
                              icon: BrandIconKind.crown,
                              title: 'Badge unlocked: ${a.title}',
                              body: a.description,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.xs,
                    Space.gutter,
                    Space.md,
                  ),
                  child: AppButton(
                    key: const ValueKey('complete_continue'),
                    label: 'Continue',
                    variant: AppButtonVariant.success,
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
                  ),
                ),
              ],
            ),
          ),
          const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.child,
    required this.semantic,
    this.suffix,
  });

  final String label;
  final Color color;
  final BrandIconKind icon;
  final Widget child;
  final String semantic;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantic,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                label.toUpperCase(),
                style: AppType.overline.copyWith(fontSize: 11),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandIcon(icon, size: 22),
                    const SizedBox(width: 4),
                    child,
                    if (suffix != null) Text(suffix!, style: AppType.headline),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.reward});
  final LessonReward reward;

  @override
  Widget build(BuildContext context) {
    final lvl = reward.levelAfter;
    final sameLevel = !reward.leveledUp;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.indigo,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reward.leveledUp
                          ? 'LEVEL UP! · LEVEL ${lvl.level}'
                          : 'LEVEL ${lvl.level}',
                      style: AppType.overline.copyWith(color: AppColors.gold),
                    ),
                    const Spacer(),
                    Text(
                      '${lvl.xpIntoLevel}/${lvl.xpForLevel} XP',
                      style: AppType.caption.copyWith(
                        color: AppColors.onIndigoMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppProgressBar(
                  value: lvl.fraction,
                  from: sameLevel ? reward.levelBefore.fraction : 0,
                  color: AppColors.gold,
                  track: AppColors.indigoRaised,
                  semanticLabel: 'Level progress',
                ),
                const SizedBox(height: Space.md),
                Row(
                  children: [
                    Text(
                      'UNIT PROGRESS',
                      style: AppType.overline.copyWith(color: AppColors.teal),
                    ),
                    const Spacer(),
                    Text(
                      '${(reward.unitProgressAfter * 100).round()}%',
                      style: AppType.caption.copyWith(
                        color: AppColors.onIndigoMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppProgressBar(
                  value: reward.unitProgressAfter,
                  from: reward.unitProgressBefore,
                  color: AppColors.teal,
                  track: AppColors.indigoRaised,
                  semanticLabel: 'Unit progress',
                ),
              ],
            ),
          ),
          const TibebBand(height: 8),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });
  final Color color;
  final BrandIconKind icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(Space.md),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        BrandIcon(icon, size: 32),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppType.label),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppType.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
