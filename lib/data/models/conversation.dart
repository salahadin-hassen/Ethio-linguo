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

/// One transcript line in a conversation.
class TutorTurn {
  const TutorTurn({
    required this.speaker,
    required this.text,
    this.translation,
    this.feedback,
    this.usedExpressions = const [],
    this.sttConfidence,
  });

  final Speaker speaker;
  final String text;

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
