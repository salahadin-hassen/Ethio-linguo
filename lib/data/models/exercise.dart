/// Resolved exercises — plain strings in the learner's language pair.
///
/// These are what the UI renders and what [AnswerValidator] checks. They are
/// produced from authored specs by `LessonBuilder` so content stays separate
/// from presentation and validation logic.
sealed class Exercise {
  const Exercise({
    required this.id,
    required this.instruction,
    required this.nativeInstruction,
    required this.termIds,
  });

  final String id;
  final String instruction;
  final String nativeInstruction;

  /// Vocabulary practised by this exercise (feeds the Word Garden).
  final List<String> termIds;

  /// Human-readable correct answer, shown in feedback.
  String get solutionText;
}

/// Pick one option. Used for both directions (native->English, English->native).
class MultipleChoiceExercise extends Exercise {
  const MultipleChoiceExercise({
    required super.id,
    required super.instruction,
    required super.nativeInstruction,
    required super.termIds,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;

  @override
  String get solutionText => options[correctIndex];
}

/// Type the English translation of a single word or short phrase.
class TypeAnswerExercise extends Exercise {
  const TypeAnswerExercise({
    required super.id,
    required super.instruction,
    required super.nativeInstruction,
    required super.termIds,
    required this.prompt,
    required this.acceptedAnswers,
  });

  final String prompt;
  final List<String> acceptedAnswers;

  @override
  String get solutionText => acceptedAnswers.first;
}

/// Assemble an English sentence from word tiles.
class BuildSentenceExercise extends Exercise {
  const BuildSentenceExercise({
    required super.id,
    required super.instruction,
    required super.nativeInstruction,
    required super.termIds,
    required this.prompt,
    required this.answer,
    required this.tiles,
  });

  final String prompt;
  final List<String> answer;

  /// Shuffled answer tokens plus distractors.
  final List<String> tiles;

  @override
  String get solutionText => answer.join(' ');
}

class MatchPair {
  const MatchPair(this.termId, this.native, this.english);

  final String termId;
  final String native;
  final String english;
}

/// Connect native words with their English meaning.
class MatchPairsExercise extends Exercise {
  const MatchPairsExercise({
    required super.id,
    required super.instruction,
    required super.nativeInstruction,
    required super.termIds,
    required this.pairs,
    required this.rightOrder,
  });

  final List<MatchPair> pairs;

  /// Display order (indices into [pairs]) for the English column.
  final List<int> rightOrder;

  @override
  String get solutionText =>
      pairs.map((p) => '${p.native} = ${p.english}').join(' · ');
}
