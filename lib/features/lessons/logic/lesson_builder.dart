import 'dart:math';

import '../../../data/local/instructions.dart';
import '../../../data/models/course.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/language.dart';
import '../../../data/models/localized.dart';

/// Turns authored [ExerciseSpec]s into concrete [Exercise]s for one native
/// language. Shuffling is seeded so a lesson is reproducible (and testable).
class LessonBuilder {
  LessonBuilder(this.course, this.native, {int seed = 7}) : _rng = Random(seed);

  final Course course;
  final NativeLanguage native;
  final Random _rng;

  List<Exercise> buildLesson(LessonContent lesson) => [
    for (var i = 0; i < lesson.exercises.length; i++)
      _resolve(lesson.exercises[i], '${lesson.id}_$i'),
  ];

  /// Generates a short review from a vocabulary list. Used by practice nodes,
  /// checkpoints and Word Garden "watering" sessions.
  List<Exercise> buildReview(
    List<String> termIds, {
    required String id,
    bool checkpoint = false,
  }) {
    final ids = termIds.where(course.terms.containsKey).toList()..shuffle(_rng);
    if (ids.isEmpty) return const [];
    final specs = <ExerciseSpec>[];
    List<String> distractorsFor(String t) {
      final pool = course.terms.keys.where((k) => k != t).toList()
        ..shuffle(_rng);
      return pool.take(3).toList();
    }

    final count = checkpoint ? min(ids.length, 8) : min(ids.length, 6);
    for (var i = 0; i < count; i++) {
      final t = ids[i];
      final kind = (i + (checkpoint ? 1 : 0)) % 3;
      specs.add(switch (kind) {
        0 => ChooseMeaningSpec(t, distractorsFor(t)),
        1 => ChooseTranslationSpec(t, distractorsFor(t)),
        _ => TypeAnswerSpec(t),
      });
    }
    if (ids.length >= 4) {
      specs.insert(min(2, specs.length), MatchPairsSpec(ids.take(4).toList()));
    }
    return [
      for (var i = 0; i < specs.length; i++) _resolve(specs[i], '${id}_$i'),
    ];
  }

  String _n(Localized l) => l.of(native);

  Exercise _resolve(ExerciseSpec spec, String id) {
    switch (spec) {
      case ChooseMeaningSpec(:final termId, :final distractorIds):
        final term = course.terms[termId]!;
        final options = [
          term.english,
          for (final d in distractorIds) course.terms[d]!.english,
        ]..shuffle(_rng);
        return MultipleChoiceExercise(
          id: id,
          instruction: Instructions.chooseMeaning.en,
          nativeInstruction: _n(Instructions.chooseMeaning.native),
          termIds: [termId],
          prompt: _n(term.native),
          options: options,
          correctIndex: options.indexOf(term.english),
        );
      case ChooseTranslationSpec(:final termId, :final distractorIds):
        final term = course.terms[termId]!;
        final correct = _n(term.native);
        final options = [
          correct,
          for (final d in distractorIds) _n(course.terms[d]!.native),
        ]..shuffle(_rng);
        return MultipleChoiceExercise(
          id: id,
          instruction: Instructions.chooseTranslation.en,
          nativeInstruction: _n(Instructions.chooseTranslation.native),
          termIds: [termId],
          prompt: term.english,
          options: options,
          correctIndex: options.indexOf(correct),
        );
      case TypeAnswerSpec(:final termId):
        final term = course.terms[termId]!;
        return TypeAnswerExercise(
          id: id,
          instruction: Instructions.typeAnswer.en,
          nativeInstruction: _n(Instructions.typeAnswer.native),
          termIds: [termId],
          prompt: _n(term.native),
          acceptedAnswers: [term.english, ...term.alsoAccept],
        );
      case BuildSentenceSpec(:final sentenceId, :final distractorTokens):
        final s = course.sentences[sentenceId]!;
        final tiles = [...s.englishTokens, ...distractorTokens]..shuffle(_rng);
        return BuildSentenceExercise(
          id: id,
          instruction: Instructions.buildSentence.en,
          nativeInstruction: _n(Instructions.buildSentence.native),
          termIds: s.termIds,
          prompt: _n(s.native),
          answer: s.englishTokens,
          tiles: tiles,
        );
      case MatchPairsSpec(:final termIds):
        final pairs = [
          for (final t in termIds)
            MatchPair(t, _n(course.terms[t]!.native), course.terms[t]!.english),
        ];
        final order = List<int>.generate(pairs.length, (i) => i)..shuffle(_rng);
        return MatchPairsExercise(
          id: id,
          instruction: Instructions.matchPairs.en,
          nativeInstruction: _n(Instructions.matchPairs.native),
          termIds: termIds,
          pairs: pairs,
          rightOrder: order,
        );
    }
  }
}
