import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/components/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/progress.dart';
import '../../word_garden/widgets/word_plant.dart';

class GardenEntryCard extends StatelessWidget {
  const GardenEntryCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final words = app.progress.words;
    final thirsty = app.wordsNeedingWater.length;
    final blooms = words.values
        .where((w) => w.stage == GrowthStage.bloom)
        .length;
    final subtitle = words.isEmpty
        ? 'Finish a lesson to plant your first words.'
        : '${words.length} words growing · $blooms in bloom${thirsty > 0 ? ' · $thirsty need water' : ''}';
    return AppCard(
      color: AppColors.tealTint,
      borderColor: AppColors.teal.withValues(alpha: 0.35),
      onTap: onOpen,
      semanticLabel: 'Word Garden. $subtitle',
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 64,
            child: Stack(
              children: const [
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: WordPlant(stage: GrowthStage.sprout, size: 48),
                ),
                Positioned(
                  left: 28,
                  bottom: 4,
                  child: WordPlant(
                    stage: GrowthStage.bloom,
                    size: 60,
                    petal: AppColors.coral,
                  ),
                ),
                Positioned(
                  left: 62,
                  bottom: 0,
                  child: WordPlant(
                    stage: GrowthStage.bud,
                    size: 48,
                    petal: AppColors.periwinkle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Word Garden', style: AppType.title),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppType.bodySmall.copyWith(color: AppColors.tealInk),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.tealInk,
            size: 30,
          ),
        ],
      ),
    );
  }
}
