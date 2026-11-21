import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/components/app_button.dart';
import '../../core/components/brand_icons.dart';
import '../../core/components/progress_bar.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/gamification.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const _style = {
    AchievementId.firstSteps: (BrandIconKind.star, AppColors.gold),
    AchievementId.perfectionist: (BrandIconKind.gem, AppColors.teal),
    AchievementId.onFire: (BrandIconKind.flame, AppColors.coral),
    AchievementId.gardener: (BrandIconKind.leaf, AppColors.teal),
    AchievementId.firstBloom: (BrandIconKind.heart, AppColors.periwinkle),
    AchievementId.checkpoint: (BrandIconKind.crown, AppColors.gold),
    AchievementId.sceneStarter: (BrandIconKind.star, AppColors.coral),
    AchievementId.wordKeeper: (BrandIconKind.leaf, AppColors.gold),
    AchievementId.firstConversation: (BrandIconKind.heart, AppColors.teal),
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final list = app.achievements;
    final unlocked = list.where((a) => a.unlocked).length;
    final lvl = app.level;
    return Scaffold(
      appBar: AppBar(title: const Text('Badges & progress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.xs,
          Space.gutter,
          Space.xxl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: AppColors.indigo,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                ProgressRing(
                  value: lvl.fraction,
                  size: 72,
                  stroke: 7,
                  color: AppColors.gold,
                  track: AppColors.indigoRaised,
                  child: Text(
                    '${lvl.level}',
                    style: AppType.headline.copyWith(color: AppColors.ivory),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${lvl.level}',
                        style: AppType.title.copyWith(color: AppColors.ivory),
                      ),
                      Text(
                        '${lvl.xpForLevel - lvl.xpIntoLevel} XP to level ${lvl.level + 1}',
                        style: AppType.bodySmall.copyWith(
                          color: AppColors.onIndigoMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${app.progress.totalXp} XP total · best run ${app.progress.longestCorrectRun}',
                        style: AppType.caption.copyWith(color: AppColors.gold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(child: Text('Badges', style: AppType.title)),
              Text(
                '$unlocked of ${list.length}',
                style: AppType.label.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 196,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) =>
                _BadgeCard(a: list[i], style: _style[list[i].id]!),
          ),
          const SizedBox(height: Space.xl),
          Text('Device data', style: AppType.title),
          const SizedBox(height: 4),
          Text(
            'Your progress is stored only on this device. Accounts and sync arrive in a later version.',
            style: AppType.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: Space.sm),
          AppButton(
            label: 'Reset demo progress',
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.ivory,
                  title: const Text('Reset all progress?'),
                  content: const Text(
                    'This clears XP, streak, Word Garden and language choice on this device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              await AppScope.read(context).resetProgress();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.a, required this.style});
  final Achievement a;
  final (BrandIconKind, Color) style;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = style;
    return Semantics(
      label:
          '${a.title}. ${a.description}. ${a.unlocked ? 'Unlocked' : '${a.progress} of ${a.goal}'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: a.unlocked ? AppColors.surface : AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: a.unlocked ? color : AppColors.outline,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            ProgressRing(
              value: a.fraction,
              size: 74,
              stroke: 6,
              color: a.unlocked ? color : AppColors.outlineStrong,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: a.unlocked
                      ? color.withValues(alpha: 0.22)
                      : AppColors.disabledFill,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: BrandIcon(icon, muted: !a.unlocked),
              ),
            ),
            const SizedBox(height: 8),
            Text(a.title, textAlign: TextAlign.center, style: AppType.label),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                a.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
            Text(
              a.unlocked ? 'UNLOCKED' : '${a.progress}/${a.goal}',
              style: AppType.overline.copyWith(
                color: a.unlocked ? AppColors.tealInk : AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
