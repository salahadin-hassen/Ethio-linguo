import 'package:flutter/material.dart';

import '../../../core/components/shake.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../logic/answer_validator.dart';
import '../widgets/answer_tile.dart';

/// Tap tiles from the bank to build the sentence; tap a placed tile to
/// return it. [placed] holds indices into [BuildSentenceExercise.tiles].
class BuildSentenceView extends StatelessWidget {
  const BuildSentenceView({
    super.key,
    required this.exercise,
    required this.placed,
    required this.verdict,
    required this.onAdd,
    required this.onRemoveAt,
  });

  final BuildSentenceExercise exercise;
  final List<int> placed;
  final Verdict? verdict;

  /// Intents (not new lists) so rapid taps never act on stale state.
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    final locked = verdict != null;
    final tone = switch (verdict) {
      Verdict.correct || Verdict.almost => TileTone.correct,
      Verdict.incorrect => TileTone.wrong,
      null => TileTone.idle,
    };
    return Column(
      children: [
        Shake(
          trigger: verdict == Verdict.incorrect ? 1 : 0,
          child: Semantics(
            label: placed.isEmpty
                ? 'Answer area, empty'
                : 'Your answer: ${placed.map((i) => exercise.tiles[i]).join(' ')}',
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.fast),
              constraints: const BoxConstraints(minHeight: 120),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.outlineStrong, width: 2),
                  bottom: BorderSide(color: AppColors.outlineStrong, width: 2),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final (pos, i) in placed.indexed)
                    AnswerTile(
                      key: ValueKey('placed_$i'),
                      compact: true,
                      label: exercise.tiles[i],
                      tone: tone,
                      semanticLabel: 'Remove ${exercise.tiles[i]}',
                      onTap: locked ? null : () => onRemoveAt(pos),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 10,
          children: [
            for (var i = 0; i < exercise.tiles.length; i++)
              placed.contains(i)
                  ? Opacity(
                      opacity: 0.6,
                      child: AnswerTile(
                        compact: true,
                        label: exercise.tiles[i],
                        tone: TileTone.disabled,
                        onTap: null,
                      ),
                    )
                  : AnswerTile(
                      key: ValueKey('bank_$i'),
                      compact: true,
                      label: exercise.tiles[i],
                      tone: TileTone.idle,
                      semanticLabel: 'Add ${exercise.tiles[i]}',
                      onTap: locked ? null : () => onAdd(i),
                    ),
          ],
        ),
      ],
    );
  }
}
