import 'package:flutter/material.dart';

import '../../../core/components/pressable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/progress.dart';
import 'word_plant.dart';

const stageNames = {
  GrowthStage.seed: 'Seed',
  GrowthStage.sprout: 'Sprout',
  GrowthStage.bud: 'Bud',
  GrowthStage.bloom: 'Bloom',
};

const petalColors = [
  AppColors.coral,
  AppColors.periwinkle,
  AppColors.gold,
  AppColors.teal,
];

class GardenPlot extends StatelessWidget {
  const GardenPlot({
    super.key,
    required this.native,
    required this.english,
    required this.word,
    required this.thirsty,
    required this.petal,
    required this.onTap,
  });

  final String native;
  final String english;
  final WordProgress word;
  final bool thirsty;
  final Color petal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      color: AppColors.surface,
      shade: AppColors.outline,
      border: Border.all(
        color: thirsty ? AppColors.periwinkle : AppColors.outline,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(20),
      semanticLabel:
          '$native, $english, ${stageNames[word.stage]}${thirsty ? ', needs water' : ''}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WordPlant(
                stage: word.stage,
                petal: petal,
                size: 64,
                thirsty: thirsty,
              ),
              const SizedBox(height: 4),
              Text(
                native,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.titleSmall,
              ),
              Text(
                english,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i <= WordProgress.maxStrength; i++)
                    Container(
                      width: 14,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: i <= word.strength
                            ? AppColors.teal
                            : AppColors.outline,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
