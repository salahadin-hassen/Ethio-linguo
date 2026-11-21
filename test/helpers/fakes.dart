import 'package:ethio_linguo/data/models/conversation.dart';
import 'package:ethio_linguo/services/speech/speech_services.dart';
import 'package:ethio_linguo/services/tutor/tutor_engine.dart';

/// Test double for a LIVE tutor provider. Used only in tests; the app never
/// ships a scripted tutor presented as AI.
class FakeLiveTutor implements TutorEngine {
  final requests = <TutorRequest>[];
  TutorException? failWith;

  @override
  Future<TutorAvailability> availability() async =>
      const TutorAvailability.live(provider: 'fake');

  @override
  Future<TutorResponse> respond(TutorRequest r) async {
    requests.add(r);
    if (failWith != null) throw failWith!;
    if (r.utterance == null) {
      return const TutorResponse(
        replyText: 'Hey! Long time no see! How have you been?',
        replyTranslation: '<ai translation>',
      );
    }
    final used = [
      for (final e in r.context.targetExpressions)
        if (r.utterance!.toLowerCase().contains(e.toLowerCase())) e,
    ];
    return TutorResponse(
      replyText: 'Reply to: ${r.utterance}',
      replyTranslation: '<ai translation>',
      feedback: used.isEmpty
          ? const TutorFeedback(
              kind: FeedbackKind.grammar,
              note: 'Add "have".',
              suggestion: 'I have been busy.',
            )
          : const TutorFeedback(kind: FeedbackKind.great, note: 'Natural!'),
      usedExpressions: used,
    );
  }
}

class FakeRecognizer implements SpeechRecognizer {
  FakeRecognizer({this.ok = true, this.say = 'Long time no see'});
  final bool ok;
  final String say;
  bool _init = false;

  @override
  bool get available => _init && ok;

  @override
  Future<bool> initialize() async => _init = ok;

  @override
  Future<void> listen({
    required String localeId,
    required void Function(RecognizedSpeech) onResult,
  }) async {
    onResult(RecognizedSpeech(say.split(' ').first, isFinal: false));
    onResult(RecognizedSpeech(say, confidence: 0.9, isFinal: true));
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> cancel() async {}
}

class FakeSynth implements SpeechSynthesizer {
  final spoken = <String>[];
  @override
  bool get available => true;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<void> speak(String text, {required String localeId}) async =>
      spoken.add(text);
  @override
  Future<void> stop() async {}
}
