import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/empty_state.dart';
import '../../../core/components/progress_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../learning_path/node_actions.dart';
import '../../mascot/mascot.dart';

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final node = app.currentNode;
    if (node == null) {
      return const AppCard(
        child: EmptyState(
          mood: MascotMood.celebrating,
          title: 'You finished everything!',
          message: 'New units are on the way. Water your Word Garden to keep words fresh.',
          mascotSize: 110,
        ),
      );
    }
    final unit = app.course.unitOf(node.id);
    final index = unit.nodes.indexOf(node) + 1;
    final started = app.progress.completedNodeIds.isNotEmpty;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              Space.md,
              Space.md,
              Space.md,
            ),
            decoration: BoxDecoration(
              color: unit.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIT ${unit.number} · STEP $index OF ${unit.nodes.length}',
                        style: AppType.overline,
                      ),
                      const SizedBox(height: 2),
                      Text(node.title, style: AppType.headline),
                      Text(unit.title, style: AppType.bodySmall),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 36,
                    color: AppColors.indigo,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Unit progress',
                      style: AppType.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(app.unitProgress(unit) * 100).round()}%',
                      style: AppType.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AppProgressBar(
                  value: app.unitProgress(unit),
                  color: unit.color,
                  semanticLabel: 'Unit ${unit.number} progress',
                ),
                const SizedBox(height: Space.md),
                AppButton(
                  key: const ValueKey('continue_learning'),
                  label: started ? 'Continue' : 'Start lesson',
                  onPressed: () => openPathNode(context, node),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
