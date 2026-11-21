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
    this.utteranceLanguage = 'en',
    this.characterId = 'professor',
  });

  /// 'en' when the learner practises English, 'am'/'om' for a question
  /// asked in their own language.
  final String utteranceLanguage;

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
    this.coach,
    this.task,
    this.hint,
  });

  /// Teaching explanation in the learner's language (AI-generated).
  final String? coach;
  final TutorTask? task;

  /// A sample English answer for [task].
  final String? hint;

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

/// Synthesised audio clip.
class SpeechClip {
  const SpeechClip(this.bytes, this.mimeType, {this.envelope});
  final List<int> bytes;
  final String mimeType;

  /// Loudness of the clip over time, measured from the real audio by the
  /// relay. Null when the provider returned a format we cannot measure.
  final AmplitudeEnvelope? envelope;
}

/// Per-frame loudness (0..1) of a clip. Drives the speaking character's jaw
/// while the clip plays. Amplitude only: it is NOT phoneme/viseme lip-sync.
class AmplitudeEnvelope {
  const AmplitudeEnvelope(this.frameMs, this.values);
  final int frameMs;
  final List<double> values;

  static AmplitudeEnvelope? fromJson(Object? j) {
    if (j is! Map) return null;
    final ms = j['frameMs'];
    final v = j['values'];
    if (ms is! num || ms <= 0 || v is! List || v.isEmpty) return null;
    return AmplitudeEnvelope(ms.toInt(), [
      for (final x in v) x is num ? x.toDouble().clamp(0.0, 1.0) : 0.0,
    ]);
  }

  /// Loudness at [t], linearly interpolated between frames; 0 past the end.
  double at(Duration t) {
    final f = t.inMicroseconds / 1000 / frameMs;
    if (f < 0 || f >= values.length) return 0;
    final i = f.floor();
    final a = values[i];
    final b = i + 1 < values.length ? values[i + 1] : 0.0;
    return a + (b - a) * (f - i);
  }
}

/// Native-language voice (Amharic / Afaan Oromo) for the Professor:
/// speaking coaching lines and transcribing learners' questions.
abstract interface class NativeVoice {
  Future<bool> available();
  Future<SpeechClip> synthesize(String text, {required String language});
  Future<String> transcribe(List<int> wav, {required String language});
}

class UnavailableNativeVoice implements NativeVoice {
  const UnavailableNativeVoice();
  @override
  Future<bool> available() async => false;
  @override
  Future<SpeechClip> synthesize(String text, {required String language}) =>
      throw const TutorException(
        TutorErrorCode.unavailable,
        'No voice service.',
      );
  @override
  Future<String> transcribe(List<int> wav, {required String language}) =>
      throw const TutorException(
        TutorErrorCode.unavailable,
        'No voice service.',
      );
}
