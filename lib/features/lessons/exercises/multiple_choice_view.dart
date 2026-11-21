import 'package:flutter/material.dart';

import '../../../core/components/shake.dart';
import '../../../data/models/exercise.dart';
import '../logic/answer_validator.dart';
import '../widgets/answer_tile.dart';

class MultipleChoiceView extends StatelessWidget {
  const MultipleChoiceView({
    super.key,
    required this.exercise,
    required this.selected,
    required this.verdict,
    required this.onSelect,
  });

  final MultipleChoiceExercise exercise;
  final int? selected;
  final Verdict? verdict;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final locked = verdict != null;
    return Column(
      children: [
        for (var i = 0; i < exercise.options.length; i++) ...[
          Shake(
            trigger: verdict == Verdict.incorrect && selected == i ? 1 : 0,
            child: AnswerTile(
              key: ValueKey('option_$i'),
              leading: '${i + 1}',
              label: exercise.options[i],
              tone: switch ((
                locked,
                i == selected,
                i == exercise.correctIndex,
              )) {
                (true, _, true) => TileTone.correct,
                (true, true, false) => TileTone.wrong,
                (true, false, false) => TileTone.disabled,
                (false, true, _) => TileTone.selected,
                _ => TileTone.idle,
              },
              onTap: locked ? null : () => onSelect(i),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
