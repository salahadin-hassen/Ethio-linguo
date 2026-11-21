// SHARED CONTRACT (v2): tutor conversation types. Provider-independent.

import 'language.dart';

/// Structured lesson context handed to the tutor. The tutor is a lesson
/// partner, not a generic chatbot, so this is required (may be empty for a
/// free conversation).
class TutorContext {
  const TutorContext({
    required this.native,
    this.level = LearnerLevel.beginner,
    this.target = TargetLanguage.english,
    this.contentId,
    this.contentTitle,
    this.sceneSummary = '',
    this.transcript = const [],
    this.focusExpression,
    this.targetExpressions = const [],
  });

  final NativeLanguage native;
  final LearnerLevel level;
  final TargetLanguage target;
  final String? contentId;
  final String? contentTitle;
  final String sceneSummary;

  /// "Speaker: line" strings from the scene.
  final List<String> transcript;
  final String? focusExpression;
  final List<String> targetExpressions;

  bool get hasLesson => contentId != null;
}

enum Speaker { learner, tutor }

enum FeedbackKind { great, grammar, wordChoice, pronunciation }

class TutorFeedback {
  const TutorFeedback({
    required this.kind,
    required this.note,
    this.noteNative,
    this.suggestion,
  });

  final FeedbackKind kind;
  final String note;

  /// AI-generated; the UI labels it as such.
  final String? noteNative;

  /// Corrected sentence the learner could say instead.
  final String? suggestion;
}

enum TaskType { repeat, answer, useExpression }

/// What the Professor asks the learner to say next.
class TutorTask {
  const TutorTask({
    required this.type,
    required this.prompt,
    this.promptNative,
  });

  final TaskType type;

  /// Exact English sentence (repeat) or English question (answer).
  final String prompt;
  final String? promptNative;
}

/// One transcript line in a conversation.
class TutorTurn {
  const TutorTurn({
    required this.speaker,
    required this.text,
    this.translation,
    this.feedback,
    this.usedExpressions = const [],
    this.sttConfidence,
    this.coach,
    this.task,
    this.hint,
    this.language = 'en',
    this.repeatScore,
  });

  final Speaker speaker;
  final String text;

  /// Tutor only: teaching explanation in the learner's language (AI).
  final String? coach;

  /// Tutor only: what to say next, and a sample answer.
  final TutorTask? task;
  final String? hint;

  /// Learner only: 'en' when practising, 'am'/'om' for a native question.
  final String language;

  /// Learner only: local word-match result for a "repeat" task.
  final RepeatScore? repeatScore;

  TutorTurn copyWith({
    TutorFeedback? feedback,
    List<String>? usedExpressions,
  }) => TutorTurn(
    speaker: speaker,
    text: text,
    translation: translation,
    feedback: feedback ?? this.feedback,
    usedExpressions: usedExpressions ?? this.usedExpressions,
    sttConfidence: sttConfidence,
    coach: coach,
    task: task,
    hint: hint,
    language: language,
    repeatScore: repeatScore,
  );

  /// AI translation of a tutor line (labelled in the UI).
  final String? translation;
  final TutorFeedback? feedback;
  final List<String> usedExpressions;
  final double? sttConfidence;
}

/// Summary kept after a conversation ends. Full transcripts are not
/// persisted (privacy default); only what the learner needs for review.
class ConversationSession {
  const ConversationSession({
    required this.id,
    required this.tutorCharacterId,
    required this.native,
    required this.createdAt,
    required this.learnerTurns,
    this.contentId,
    this.usedExpressions = const [],
    this.suggestions = const [],
  });

  final String id;
  final String tutorCharacterId;
  final NativeLanguage native;
  final String? contentId;
  final DateTime createdAt;
  final int learnerTurns;
  final List<String> usedExpressions;

  /// Corrected sentences the tutor suggested (post-conversation review).
  final List<String> suggestions;
}

/// Word-level comparison of what was recognised against the sentence the
/// learner was asked to repeat. Based on speech RECOGNITION output, so it
/// measures intelligibility, not phoneme-level pronunciation.
class RepeatScore {
  const RepeatScore({required this.words, required this.matched});

  /// Target words in order, each with whether it was heard.
  final List<({String word, bool heard})> words;
  final int matched;

  double get ratio => words.isEmpty ? 0 : matched / words.length;
  bool get passed => ratio >= 0.8;
  List<String> get missing => [
    for (final w in words)
      if (!w.heard) w.word,
  ];
}

String _norm(String w) => w
    .toLowerCase()
    .replaceAll('\u2019', "'")
    .replaceAll(RegExp(r"[^a-z0-9']"), '');

/// Expands common contractions so "I've" matches "I have" and vice versa.
List<String> _tokens(String s) {
  const expand = {
    "i've": ['i', 'have'],
    "i'm": ['i', 'am'],
    "let's": ['let', 'us'],
    "that's": ['that', 'is'],
    "it's": ['it', 'is'],
    "you're": ['you', 'are'],
    "don't": ['do', 'not'],
    "can't": ['can', 'not'],
  };
  return [
    for (final raw in s.split(RegExp(r'\s+')))
      if (_norm(raw).isNotEmpty) ...(expand[_norm(raw)] ?? [_norm(raw)]),
  ];
}

RepeatScore scoreRepeat(String target, String said) {
  final heard = _tokens(said);
  final pool = <String, int>{};
  for (final w in heard) {
    pool[w] = (pool[w] ?? 0) + 1;
  }
  final out = <({String word, bool heard})>[];
  var matched = 0;
  for (final raw in target.split(RegExp(r'\s+'))) {
    final parts = _tokens(raw);
    if (parts.isEmpty) continue;
    final ok = parts.every((p) => (pool[p] ?? 0) > 0);
    if (ok) {
      for (final p in parts) {
        pool[p] = pool[p]! - 1;
      }
      matched++;
    }
    out.add((word: raw.replaceAll(RegExp(r'[.,!?]+$'), ''), heard: ok));
  }
  return RepeatScore(words: out, matched: matched);
}
