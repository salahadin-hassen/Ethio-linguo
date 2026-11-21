import 'package:flutter/material.dart';

import '../../core/components/animated_count.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_sheet.dart';
import '../../core/components/brand_icons.dart';
import '../../core/components/confetti.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/activity.dart';
import '../mascot/mascot.dart';

/// Shared celebration for any completed activity. Values come only from the
/// [ActivityReward] the progress service returned — nothing is invented here.
Future<void> showActivityReward(
  BuildContext context,
  ActivityReward reward, {
  required String title,
  String? detail,
  String? primaryLabel,
  VoidCallback? onPrimary,
}) => showAppSheet<void>(
  context,
  builder: (ctx) => Stack(
    alignment: Alignment.topCenter,
    children: [
      Column(
        key: const ValueKey('reward_sheet'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(mood: MascotMood.celebrating, size: 120),
          const SizedBox(height: Space.sm),
          Text(title, style: AppType.headline, textAlign: TextAlign.center),
          if (detail != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: Space.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stat(
                icon: BrandIconKind.xp,
                label: 'XP earned',
                child: AnimatedCount(
                  value: reward.xpEarned,
                  prefix: '+',
                  style: AppType.title,
                ),
              ),
              const SizedBox(width: Space.md),
              _Stat(
                icon: BrandIconKind.flame,
                label: reward.streakExtended ? 'Streak extended' : 'Day streak',
                child: Text('${reward.streakAfter}', style: AppType.title),
              ),
            ],
          ),
          if (!reward.firstCompletion) ...[
            const SizedBox(height: Space.sm),
            Text(
              'Practice again earns reduced XP.',
              style: AppType.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
          if (reward.leveledUp) ...[
            const SizedBox(height: Space.sm),
            Text(
              'Level ${reward.levelAfter.level} reached!',
              style: AppType.label.copyWith(color: AppColors.goldInk),
            ),
          ],
          for (final a in reward.newAchievements) ...[
            const SizedBox(height: Space.sm),
            Text(
              'Badge unlocked: ${a.title}',
              style: AppType.label.copyWith(color: AppColors.tealInk),
            ),
          ],
          const SizedBox(height: Space.lg),
          if (primaryLabel != null)
            AppButton(
              key: const ValueKey('reward_primary'),
              label: primaryLabel,
              onPressed: () {
                Navigator.pop(ctx);
                onPrimary?.call();
              },
            ),
          const SizedBox(height: Space.xs),
          AppButton(
            key: const ValueKey('reward_done'),
            label: 'Done',
            variant: primaryLabel == null
                ? AppButtonVariant.primary
                : AppButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
      const IgnorePointer(child: SizedBox(height: 200, child: ConfettiBurst())),
    ],
  ),
);

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.child});
  final BrandIconKind icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 140,
    padding: const EdgeInsets.all(Space.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: Radii.lgAll,
      border: Border.all(color: AppColors.outline, width: 1.5),
    ),
    child: Column(
      children: [
        BrandIcon(icon, size: 28),
        const SizedBox(height: 4),
        child,
        Text(label, style: AppType.caption, textAlign: TextAlign.center),
      ],
    ),
  );
}
