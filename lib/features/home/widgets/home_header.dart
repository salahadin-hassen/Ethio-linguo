import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/components/brand_icons.dart';
import '../../../core/components/progress_bar.dart';
import '../../../core/components/stat_pill.dart';
import '../../../core/components/tibeb_band.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/progress.dart';
import '../../../app/app_services.dart';
import '../../../core/motion/motion.dart';
import '../../companion/companion_lines.dart';
import '../../mascot/mascot.dart';

/// Indigo hero: stats, personalised greeting, and Spark — who reacts to
/// real progress (XP just earned, streak, returning after a break, thirsty
/// words) and answers taps with tips.
class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  int? _seenXp;
  int _xpGain = 0;
  int _tip = -1;

  void _onSparkTap() => setState(() {
    _tip = (_tip + 1) % SparkLines.tips.length;
    _xpGain = 0;
  });

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
    // React to XP earned while the learner was in a lesson/scene/review.
    if (_seenXp != null && p.totalXp > _seenXp!) {
      _xpGain = p.totalXp - _seenXp!;
      _tip = -1;
    }
    _seenXp = p.totalXp;
    final line = _tip >= 0
        ? SparkLines.tips[_tip]
        : SparkLines.greeting(
            p: p,
            today: app.today,
            hour: hour,
            thirstyWords: app.wordsNeedingWater.length,
            questsDone: app.quests.every((q) => q.done),
            xpGainedSinceLastVisit: _xpGain,
          );
    final message = line.en;
    final native = line.native(app.native);
    final sounds = ServicesScope.of(context).sounds;

    return Container(
      // Calm, light header (Duolingo-like): stats, greeting, a single line
      // from Spark. No hero block, no chat bubble.
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline, width: 2)),
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
                    color: AppColors.textPrimary,
                    background: AppColors.surfaceSunken,
                  ),
                  const SizedBox(width: Space.xs),
                  StatPill(
                    icon: BrandIconKind.xp,
                    value: p.totalXp,
                    semanticLabel: '${p.totalXp} XP',
                    color: AppColors.textPrimary,
                    background: AppColors.surfaceSunken,
                  ),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: sounds,
                    builder: (context, _) => IconButton(
                      key: const ValueKey('home_sound_toggle'),
                      tooltip: sounds.enabled ? 'Sound on' : 'Sound off',
                      onPressed: () => sounds.setEnabled(!sounds.enabled),
                      icon: Icon(
                        sounds.enabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  StatPill(
                    icon: BrandIconKind.heart,
                    value: p.hearts,
                    semanticLabel:
                        '${p.hearts} of ${LearnerProgress.maxHearts} hearts',
                    color: AppColors.textPrimary,
                    background: AppColors.surfaceSunken,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        AnimatedSwitcher(
                          duration: Motion.of(context, Motion.card),
                          switchInCurve: Motion.emphasized,
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(a),
                              child: child,
                            ),
                          ),
                          child: Column(
                            key: ValueKey(message),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                key: const ValueKey('spark_bubble'),
                                style: AppType.body.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (native != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: Space.xs,
                                    top: 2,
                                  ),
                                  child: Text(
                                    native,
                                    style: AppType.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                            ],
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
                                  track: AppColors.surfaceSunken,
                                  height: 10,
                                ),
                              ),
                              const SizedBox(width: Space.xs),
                              Text(
                                '${level.xpIntoLevel}/${level.xpForLevel}',
                                style: AppType.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  CharacterAvatar(
                    key: const ValueKey('home_spark'),
                    character: CastMember.spark,
                    state: line.state,
                    size: 84,
                    onTap: _onSparkTap,
                    semanticLabel: 'Spark says: $message. Tap for a tip.',
                  ),
                ],
              ),
            ),
            const TibebBand(height: 4),
          ],
        ),
      ),
    );
  }
}
