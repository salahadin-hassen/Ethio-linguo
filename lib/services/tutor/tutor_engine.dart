import '../../data/models/conversation.dart';

// Provider-independent tutoring contract (docs/AI_PROVIDER_INTEGRATION.md).
// Domain types only; provider wire formats live in implementations and in
// the relay (server/).

class TutorRequest {
  const TutorRequest({
    required this.sessionId,
    required this.context,
    required this.history,
    this.utterance,
    this.sttConfidence,
    this.characterId = 'professor',
  });

  final String sessionId;
  final String characterId;
  final TutorContext context;
  final List<TutorTurn> history;

  /// Null asks the tutor to open the conversation.
  final String? utterance;
  final double? sttConfidence;
}

class TutorResponse {
  const TutorResponse({
    required this.replyText,
    this.replyTranslation,
    this.feedback,
    this.suggestedExpression,
    this.usedExpressions = const [],
    this.done = false,
    this.speechUrl,
  });

  final String replyText;
  final String? replyTranslation;
  final TutorFeedback? feedback;
  final String? suggestedExpression;
  final List<String> usedExpressions;
  final bool done;

  /// Provider-rendered audio, when a provider supplies it (none in the MVP:
  /// replies are spoken by the on-device SpeechSynthesizer).
  final String? speechUrl;
}

class TutorAvailability {
  const TutorAvailability.live({this.provider}) : live = true, reason = null;
  const TutorAvailability.unavailable(this.reason)
    : live = false,
      provider = null;

  final bool live;
  final String? provider;
  final String? reason;
}

enum TutorErrorCode {
  unavailable,
  rateLimited,
  badRequest,
  providerError,
  timeout,
}

class TutorException implements Exception {
  const TutorException(this.code, this.message);
  final TutorErrorCode code;
  final String message;
  @override
  String toString() => 'TutorException($code, $message)';
}

/// One conversational tutoring provider. Throws [TutorException].
abstract interface class TutorEngine {
  Future<TutorAvailability> availability();
  Future<TutorResponse> respond(TutorRequest request);
}

/// Used when no relay is configured: honest, never fakes a reply.
class UnavailableTutorEngine implements TutorEngine {
  const UnavailableTutorEngine([
    this.reason = 'The live Professor is not connected in this build.',
  ]);

  final String reason;

  @override
  Future<TutorAvailability> availability() async =>
      TutorAvailability.unavailable(reason);

  @override
  Future<TutorResponse> respond(TutorRequest request) async =>
      throw TutorException(TutorErrorCode.unavailable, reason);
}
