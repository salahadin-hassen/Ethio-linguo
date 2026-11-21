import 'package:flutter/painting.dart';

import 'localized.dart';

/// A vocabulary item authored once for every supported native language.
class Term {
  const Term({
    required this.id,
    required this.english,
    required this.native,
    this.alsoAccept = const [],
  });

  final String id;
  final String english;
  final Localized native;

  /// Extra English spellings accepted in typed answers.
  final List<String> alsoAccept;
}

class Sentence {
  const Sentence({
    required this.id,
    required this.englishTokens,
    required this.native,
    required this.termIds,
  });

  final String id;
  final List<String> englishTokens;
  final Localized native;
  final List<String> termIds;
}

/// Authoring-time description of an exercise, independent of native language.
sealed class ExerciseSpec {
  const ExerciseSpec();
}

/// Show the native word, choose the English meaning.
class ChooseMeaningSpec extends ExerciseSpec {
  const ChooseMeaningSpec(this.termId, this.distractorIds);
  final String termId;
  final List<String> distractorIds;
}

/// Show the English word, choose the native translation.
class ChooseTranslationSpec extends ExerciseSpec {
  const ChooseTranslationSpec(this.termId, this.distractorIds);
  final String termId;
  final List<String> distractorIds;
}

class TypeAnswerSpec extends ExerciseSpec {
  const TypeAnswerSpec(this.termId);
  final String termId;
}

class BuildSentenceSpec extends ExerciseSpec {
  const BuildSentenceSpec(this.sentenceId, this.distractorTokens);
  final String sentenceId;
  final List<String> distractorTokens;
}

class MatchPairsSpec extends ExerciseSpec {
  const MatchPairsSpec(this.termIds);
  final List<String> termIds;
}

class LessonContent {
  const LessonContent({
    required this.id,
    required this.exercises,
    required this.newTermIds,
  });

  final String id;
  final List<ExerciseSpec> exercises;

  /// Words "planted" in the Word Garden when this lesson is completed.
  final List<String> newTermIds;
}

enum NodeKind { lesson, practice, checkpoint }

class PathNode {
  const PathNode({
    required this.id,
    required this.title,
    required this.kind,
    this.lessonId,
    this.reviewTermIds = const [],
  });

  final String id;
  final String title;
  final NodeKind kind;

  /// Authored lesson, if any.
  final String? lessonId;

  /// For practice/checkpoint nodes: vocabulary to generate a review from.
  final List<String> reviewTermIds;

  /// Whether playable content exists in this build.
  bool get hasContent => lessonId != null || reviewTermIds.isNotEmpty;
}

class Unit {
  const Unit({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.shade,
    required this.nodes,
  });

  final String id;
  final int number;
  final String title;
  final String subtitle;
  final Color color;
  final Color shade;
  final List<PathNode> nodes;
}

class Course {
  const Course({
    required this.units,
    required this.terms,
    required this.sentences,
    required this.lessons,
  });

  final List<Unit> units;
  final Map<String, Term> terms;
  final Map<String, Sentence> sentences;
  final Map<String, LessonContent> lessons;

  List<PathNode> get allNodes => [for (final u in units) ...u.nodes];

  PathNode? nodeById(String id) {
    for (final n in allNodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  Unit unitOf(String nodeId) =>
      units.firstWhere((u) => u.nodes.any((n) => n.id == nodeId));
}
