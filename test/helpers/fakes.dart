import 'package:ethio_linguo/data/models/conversation.dart';
import 'package:ethio_linguo/services/speech/speech_services.dart';

import 'dart:typed_data';

import 'package:ethio_linguo/services/audio/audio_services.dart';
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
        coach: '<coaching in learner language>',
        task: TutorTask(
          type: TaskType.repeat,
          prompt: 'Long time no see!',
          promptNative: '<native>',
        ),
        hint: 'Long time no see, Liya!',
      );
    }
    final used = [
      for (final e in r.context.targetExpressions)
        if (r.utterance!.toLowerCase().contains(e.toLowerCase())) e,
    ];
    if (r.utteranceLanguage != 'en') {
      return TutorResponse(
        replyText: 'Good question!',
        coach: 'Answer to: ${r.utterance}',
        task: const TutorTask(
          type: TaskType.answer,
          prompt: 'How have you been?',
        ),
        hint: 'I have been busy.',
      );
    }
    return TutorResponse(
      replyText: 'Reply to: ${r.utterance}',
      replyTranslation: '<ai translation>',
      coach: '<coach>',
      task: const TutorTask(
        type: TaskType.answer,
        prompt: 'How have you been?',
      ),
      hint: 'I have been busy with my new job.',
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

/// Delivers each phrase once (one per listen); afterwards it keeps
/// "listening" silently, like a real mic waiting for speech.
class FakeRecognizer implements SpeechRecognizer {
  FakeRecognizer({
    this.ok = true,
    String say = 'Long time no see',
    List<String>? phrases,
  }) : _queue = [
         ...(phrases ?? [say]),
       ];
  final bool ok;
  final List<String> _queue;
  bool _init = false;

  @override
  bool get available => _init && ok;

  @override
  Future<bool> initialize() async => _init = ok;

  @override
  Future<void> listen({
    required String localeId,
    required void Function(RecognizedSpeech) onResult,
    void Function(double level)? onLevel,
  }) async {
    if (_queue.isEmpty) return;
    onLevel?.call(0.7);
    final say = _queue.removeAt(0);
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

class FakeNativeVoice implements NativeVoice {
  final spoken = <String>[];
  String transcript = 'catch up ማለት ምን ማለት ነው?';
  @override
  Future<bool> available() async => true;
  @override
  Future<SpeechClip> synthesize(String text, {required String language}) async {
    spoken.add('$language:$text');
    return const SpeechClip([0, 1, 2], 'audio/mpeg');
  }

  @override
  Future<String> transcribe(List<int> wav, {required String language}) async =>
      transcript;
}

class FakeRecorder implements VoiceRecorder {
  @override
  Stream<double> get levels => const Stream.empty();
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<void> start() async {}
  @override
  Future<Uint8List?> stop() async => Uint8List(32000);
  @override
  Future<void> cancel() async {}
}

class FakeClipPlayer implements AudioClipPlayer {
  int plays = 0;
  @override
  Future<void> play(Uint8List bytes, {required String mimeType}) async =>
      plays++;
  @override
  Future<void> stop() async {}
}
