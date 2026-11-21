import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../app/app_controller.dart';
import '../../app/app_services.dart';
import '../../core/util/local_id.dart';
import '../../data/models/activity.dart';
import '../../data/models/conversation.dart';
import '../../data/models/language.dart';
import '../../data/models/vocabulary.dart';
import '../../services/analytics/analytics.dart';
import '../../services/audio/sound_effects.dart';
import '../mascot/characters.dart';
import '../../services/speech/speech_services.dart';
import '../../services/tutor/tutor_engine.dart';

/// States the Speak UI renders. Every state has a distinct visual.
enum TutorState {
  idle,
  connecting,
  listening,

  /// Recording a question in the learner's own language.
  recordingNative,

  /// Turning a native-language recording into text.
  transcribing,
  thinking,
  speaking,
  ended,

  /// No live tutor (offline, relay down, no credentials). Honest fallback.
  unavailable,
  error,
}

/// Orchestrates the teaching conversation:
/// speech-in (English via OS recognizer, or native language via the voice
/// service) -> tutor engine -> English reply (device TTS) + coaching in the
/// learner's language (native voice) -> next task. In live mode the mic
/// re-opens automatically after the Professor finishes, so the learner can
/// talk hands-free. Depends only on provider-independent interfaces.
class TutorSessionController extends ChangeNotifier {
  TutorSessionController({
    required this.context,
    required AppServices services,
    required this._progress,
  }) : _s = services;

  static const minLearnerTurnsForXp = 3;

  final TutorContext context;
  final AppServices _s;
  final AppController _progress;
  final String sessionId = newLocalId();

  TutorState state = TutorState.idle;
  final List<TutorTurn> turns = [];
  String partial = '';
  String? message;
  bool micAvailable = true;
  bool englishVoice = false;
  bool nativeVoiceAvailable = false;

  /// Hands-free: re-open the mic after each Professor turn.
  bool liveMode = true;

  /// Speak coaching aloud in the learner's language.
  bool speakCoaching = true;

  /// Show translations of the Professor's English lines.
  bool showTranslations = true;

  final Set<String> savedCorrections = {};

  /// REAL microphone level (0..1) while listening/recording; null when the
  /// platform reports none (then the UI shows no meter rather than a fake).
  final ValueNotifier<double?> level = ValueNotifier(null);
  StreamSubscription<double>? _levelSub;

  /// Loudness (0..1) of the Professor's native-language clip at the current
  /// playback position, from the relay's envelope of the real audio. Null
  /// when nothing measurable is playing (on-device English TTS reports no
  /// level, so the rig then uses its authored talk loop). Drives the jaw by
  /// amplitude only; this is not phoneme lip-sync.
  final ValueNotifier<double?> voiceLevel = ValueNotifier(null);

  /// The Professor's expression, derived from real session events
  /// (docs/INTERACTION_STATE_MAP.md §Professor).
  CharacterState get professorState => switch (state) {
    TutorState.connecting => CharacterState.greeting,
    TutorState.listening ||
    TutorState.recordingNative => CharacterState.listening,
    TutorState.transcribing => CharacterState.transcribing,
    TutorState.thinking => CharacterState.thinking,
    TutorState.speaking => CharacterState.speaking,
    TutorState.error => CharacterState.confused,
    TutorState.ended => CharacterState.celebrating,
    TutorState.unavailable => CharacterState.sleeping,
    TutorState.idle => _verdictState,
  };

  /// After the Professor answers: approving if the learner got it right,
  /// correcting if there is a fix to practise, otherwise attentive idle.
  CharacterState get _verdictState {
    TutorTurn? learner;
    for (final t in turns.reversed) {
      if (t.speaker == Speaker.learner) {
        learner = t;
        break;
      }
    }
    if (learner == null) return CharacterState.idle;
    final f = learner.feedback;
    final rep = learner.repeatScore;
    if (f?.kind == FeedbackKind.great || (rep?.passed ?? false)) {
      return CharacterState.approving;
    }
    if (f != null || (rep != null && !rep.passed)) {
      return CharacterState.correcting;
    }
    return CharacterState.idle;
  }

  int _failures = 0;
  bool _disposed = false;

  /// Bumped whenever the current exchange is abandoned (barge-in, end):
  /// every await in the speaking pipeline checks it and stops quietly.
  int _epoch = 0;

  /// Sends a "repeat" attempt as soon as every target word was heard,
  /// instead of waiting for the recognizer's silence timeout.
  Timer? _endpoint;
  Timer? _autoRetry;

  /// How long to wait, after the English line, for the coaching audio
  /// before moving on (the text stays on screen with a replay button).
  static const coachAudioPatience = Duration(seconds: 8);

  /// How long to wait for the natural (relay) English voice before speaking
  /// with the phone's own voice instead. Never both for the same line.
  static const englishVoicePatience = Duration(milliseconds: 3500);
  RecognizedSpeech? _last;
  ActivityReward? reward;

  int get learnerTurns => turns
      .where((t) => t.speaker == Speaker.learner && t.language == 'en')
      .length;
  bool get canTalk => state == TutorState.idle;
  NativeLanguage get native => context.native;

  TutorTurn? get lastTutorTurn {
    for (final t in turns.reversed) {
      if (t.speaker == Speaker.tutor) return t;
    }
    return null;
  }

  /// The learner's current assignment (shown pinned above the mic).
  TutorTask? get currentTask => lastTutorTurn?.task;

  void _set(TutorState s, {String? msg}) {
    if (s != TutorState.listening) {
      _endpoint?.cancel();
      _endpoint = null;
    }
    if (s != TutorState.listening && s != TutorState.recordingNative) {
      level.value = null; // meter only while the mic is really open
      unawaited(_levelSub?.cancel());
      _levelSub = null;
    }
    state = s;
    message = msg;
    if (!_disposed) notifyListeners();
  }

  void toggleLive() {
    liveMode = !liveMode;
    notifyListeners();
    if (liveMode && canTalk) unawaited(startListening());
  }

  void toggleCoachVoice() {
    speakCoaching = !speakCoaching;
    if (!speakCoaching) unawaited(_s.clipPlayer.stop());
    notifyListeners();
  }

  void toggleTranslations() {
    showTranslations = !showTranslations;
    notifyListeners();
  }

  Future<void> start() async {
    _set(TutorState.connecting);
    final a = await _s.tutor.availability();
    if (_disposed) return;
    if (!a.live) {
      _set(TutorState.unavailable, msg: a.reason);
      return;
    }
    final results = await Future.wait([
      _s.speechOut.initialize(),
      _s.nativeVoice.available(),
    ]);
    englishVoice = results[0];
    nativeVoiceAvailable = results[1];
    _s.analytics.log(AnalyticsEvent.tutorSessionStarted, {
      'withLesson': context.hasLesson,
    });
    await _exchange(null, null);
  }

  // ---------- English speech (practice) ----------

  Future<void> startListening() async {
    if (!canTalk) return;
    if (!_s.speechIn.available && !await _s.speechIn.initialize()) {
      micAvailable = false;
      liveMode = false;
      _set(
        TutorState.idle,
        msg:
            'Speech recognition is unavailable here. Type your answer instead.',
      );
      return;
    }
    await _stopVoices();
    partial = '';
    _last = null;
    _set(TutorState.listening);
    await _s.speechIn.listen(
      localeId: Languages.en.speechLocale!,
      onLevel: (v) => level.value = v,
      onResult: (r) {
        if (state != TutorState.listening) return;
        _last = r;
        partial = r.text;
        if (r.isFinal) {
          if (r.text.trim().isEmpty) {
            _set(
              TutorState.idle,
              msg: 'I didn\'t catch that. Tap the mic and try again.',
            );
          } else {
            unawaited(_submit(r.text, r.confidence));
          }
          return;
        }
        _maybeEndpoint(r.text);
        if (!_disposed) notifyListeners();
      },
    );
  }

  /// Smart end-of-turn for "repeat" tasks: once every target word has been
  /// heard and the learner pauses briefly, send it. Saves the recognizer's
  /// multi-second silence wait on the most common turn type.
  void _maybeEndpoint(String heard) {
    final task = currentTask;
    if (task?.type != TaskType.repeat) return;
    if (!scoreRepeat(task!.prompt, heard).passed) return;
    _endpoint?.cancel();
    _endpoint = Timer(const Duration(milliseconds: 700), () {
      if (state == TutorState.listening && partial == heard) {
        unawaited(stopListening());
      }
    });
  }

  /// Tap-to-stop (or hold release). Sends whatever was heard so far.
  Future<void> stopListening() async {
    if (state != TutorState.listening) return;
    _endpoint?.cancel();
    await _s.speechIn.stop();
    // A final result may still arrive and submit; give it a moment.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (state == TutorState.listening) {
      final text = _last?.text ?? partial;
      if (text.trim().isEmpty) {
        _set(
          TutorState.idle,
          msg: 'I didn\'t catch that. Tap the mic and speak.',
        );
      } else {
        await _submit(text, _last?.confidence);
      }
    }
  }

  /// Barge-in: cut the Professor off and start talking right away.
  Future<void> interruptAndListen() async {
    if (state == TutorState.speaking) await interrupt();
    await startListening();
  }

  /// Barge-in for a question in the learner's own language.
  Future<void> interruptAndAsk() async {
    if (state == TutorState.speaking) await interrupt();
    await startNativeQuestion();
  }

  // ---------- Native-language questions ----------

  Future<void> startNativeQuestion() async {
    if (!canTalk || !nativeVoiceAvailable) return;
    if (!await _s.recorder.hasPermission()) {
      _set(
        TutorState.idle,
        msg: 'Microphone permission is needed to ask by voice.',
      );
      return;
    }
    await _stopVoices();
    await _s.recorder.start();
    _set(TutorState.recordingNative);
    _levelSub = _s.recorder.levels.listen((v) => level.value = v);
  }

  Future<void> stopNativeQuestion() async {
    if (state != TutorState.recordingNative) return;
    final Uint8List? wav = await _s.recorder.stop();
    if (wav == null) {
      _set(TutorState.idle, msg: 'That was too short. Tap and ask again.');
      return;
    }
    _set(TutorState.transcribing);
    try {
      final text = await _s.nativeVoice.transcribe(wav, language: native.code);
      if (text.isEmpty) {
        _set(TutorState.idle, msg: 'I couldn\'t hear a question. Try again.');
        return;
      }
      await _submit(text, null, language: native.code);
    } on TutorException catch (e) {
      _set(TutorState.error, msg: e.message);
    }
  }

  // ---------- Typed input ----------

  Future<void> sendText(String text, {String language = 'en'}) async {
    if (text.trim().isEmpty || !canTalk) return;
    await _submit(text.trim(), null, language: language);
  }

  Future<void> retry() async {
    if (state != TutorState.error) return;
    _autoRetry?.cancel();
    final lastLearner = turns.lastWhere(
      (t) => t.speaker == Speaker.learner,
      orElse: () => const TutorTurn(speaker: Speaker.learner, text: ''),
    );
    if (lastLearner.text.isEmpty) {
      await _exchange(null, null);
    } else {
      turns.remove(lastLearner);
      await _submit(
        lastLearner.text,
        lastLearner.sttConfidence,
        language: lastLearner.language,
        sound: false,
      );
    }
  }

  /// Replays the Professor's last coaching line in the learner's language.
  Future<void> replayCoach(TutorTurn t) async {
    if (t.coach == null || !canTalk) return;
    final epoch = ++_epoch;
    _set(TutorState.speaking);
    final clip = await _fetchClip(t.coach!);
    if (clip != null) await _playClip(clip, epoch);
    if (!_disposed && epoch == _epoch) _set(TutorState.idle);
  }

  /// Speaks an English sentence (e.g. the task) with the device voice.
  Future<void> sayEnglish(String text) async {
    if (!englishVoice || !canTalk) return;
    final epoch = ++_epoch;
    _set(TutorState.speaking);
    await _s.speechOut.speak(text, localeId: Languages.en.speechLocale!);
    if (!_disposed && epoch == _epoch) _set(TutorState.idle);
  }

  // ---------- Core exchange ----------

  Future<void> _submit(
    String text,
    double? confidence, {
    String language = 'en',
    bool sound = true,
  }) async {
    final task = currentTask;
    final repeat = language == 'en' && task?.type == TaskType.repeat
        ? scoreRepeat(task!.prompt, text)
        : null;
    turns.add(
      TutorTurn(
        speaker: Speaker.learner,
        text: text,
        sttConfidence: confidence,
        language: language,
        repeatScore: repeat,
      ),
    );
    // Instant, honest feedback for a repeat: the word match is computed on
    // the device from what was actually heard, so it needs no round trip.
    if (repeat != null && sound) {
      _s.sounds.play(repeat.passed ? Sfx.correct : Sfx.tap);
    }
    partial = '';
    await _exchange(text, confidence, language: language);
  }

  Future<void> _exchange(
    String? utterance,
    double? confidence, {
    String language = 'en',
  }) async {
    final epoch = ++_epoch;
    _autoRetry?.cancel();
    _set(TutorState.thinking);
    final wantsVoice = speakCoaching && nativeVoiceAvailable;
    TutorTurn? early;
    Future<void>? english;
    final TutorResponse r;
    try {
      r = await _s.tutor.respond(
        TutorRequest(
          sessionId: sessionId,
          context: context,
          history: List.unmodifiable(
            utterance == null ? turns : turns.sublist(0, turns.length - 1),
          ),
          utterance: utterance,
          sttConfidence: confidence,
          utteranceLanguage: language,
          wantsVoice: wantsVoice,
        ),
        // Streaming: the Professor starts talking while the rest of the
        // turn (coaching, task, feedback) is still being generated.
        onReply: (text) {
          if (_disposed || epoch != _epoch || early != null) return;
          early = TutorTurn(speaker: Speaker.tutor, text: text);
          turns.add(early!);
          _set(TutorState.speaking);
          english = _speakEnglish(text, epoch);
        },
      );
    } on TutorException catch (e) {
      if (_disposed || epoch != _epoch) return;
      if (early != null) {
        turns.remove(early);
        await _s.speechOut.stop();
      }
      _failed(e);
      return;
    }
    if (_disposed || epoch != _epoch) return;
    _failures = 0;
    if (utterance != null &&
        (r.feedback != null || r.usedExpressions.isNotEmpty)) {
      final i = turns.lastIndexWhere((t) => t.speaker == Speaker.learner);
      turns[i] = turns[i].copyWith(
        feedback: r.feedback,
        usedExpressions: r.usedExpressions,
      );
    }
    if (utterance != null &&
        language == 'en' &&
        turns.lastWhere((t) => t.speaker == Speaker.learner).repeatScore ==
            null) {
      _s.sounds.play(
        r.feedback?.kind == FeedbackKind.great ? Sfx.correct : Sfx.tap,
      );
    }
    final tutorTurn = TutorTurn(
      speaker: Speaker.tutor,
      text: r.replyText,
      translation: r.replyTranslation,
      coach: r.coach,
      task: r.task,
      hint: r.hint,
    );
    final at = early == null ? -1 : turns.indexOf(early!);
    if (at >= 0) {
      turns[at] = tutorTurn;
    } else {
      turns.add(tutorTurn);
    }
    // The relay started synthesising this as soon as the turn was ready;
    // ask for it now so it downloads while the English line is spoken.
    final coachClip = r.coach != null && wantsVoice
        ? _fetchClip(r.coach!)
        : null;
    if (state == TutorState.speaking) {
      notifyListeners();
    } else {
      _set(TutorState.speaking);
    }
    english ??= _speakEnglish(r.replyText, epoch);
    await english;
    if (_disposed || epoch != _epoch || state != TutorState.speaking) return;
    if (coachClip != null) {
      final clip = await coachClip.timeout(
        coachAudioPatience,
        onTimeout: () => null,
      );
      if (_disposed || epoch != _epoch || state != TutorState.speaking) return;
      if (clip != null) await _playClip(clip, epoch);
    }
    if (_disposed || epoch != _epoch || state != TutorState.speaking) return;
    if (r.done) {
      _set(TutorState.ended);
      return;
    }
    _set(TutorState.idle);
    if (liveMode && micAvailable) unawaited(startListening());
  }

  /// Network trouble mid-conversation is usually brief: keep the session,
  /// retry once by itself in hands-free mode, and only give up (honest
  /// "unavailable" screen) when the Professor was never reached or after
  /// repeated failures.
  void _failed(TutorException e) {
    _failures++;
    final neverConnected = !turns.any((t) => t.speaker == Speaker.tutor);
    final fatal =
        (e.code == TutorErrorCode.unavailable && neverConnected) ||
        _failures >= 3;
    _set(fatal ? TutorState.unavailable : TutorState.error, msg: e.message);
    if (!fatal &&
        liveMode &&
        _failures == 1 &&
        e.code != TutorErrorCode.badRequest) {
      _autoRetry = Timer(const Duration(milliseconds: 1500), () {
        if (!_disposed && state == TutorState.error) unawaited(retry());
      });
    }
  }

  /// Native-language audio for [text], or null if it can't be had (the line
  /// stays readable on screen; voice is a bonus, never a blocker).
  Future<SpeechClip?> _fetchClip(String text, {String? language}) async {
    try {
      return await _s.nativeVoice.synthesize(
        text,
        language: language ?? native.code,
      );
    } catch (_) {
      return null;
    }
  }

  /// The Professor's English line: his natural voice from the relay when it
  /// arrives within [englishVoicePatience], else the phone's voice. A late
  /// relay clip is dropped, so the line is never spoken twice.
  Future<void> _speakEnglish(String text, int epoch) async {
    if (_s.nativeVoice.speaksEnglish) {
      final clip = await _fetchClip(
        text,
        language: 'en',
      ).timeout(englishVoicePatience, onTimeout: () => null);
      if (_disposed || epoch != _epoch) return;
      if (clip != null) {
        await _playClip(clip, epoch, coaching: false);
        return;
      }
    }
    if (englishVoice && !_disposed && epoch == _epoch) {
      await _s.speechOut.speak(text, localeId: Languages.en.speechLocale!);
    }
  }

  Future<void> _playClip(
    SpeechClip clip,
    int epoch, {
    bool coaching = true,
  }) async {
    if (_disposed || epoch != _epoch || (coaching && !speakCoaching)) return;
    final env = clip.envelope;
    // Real position from the player, interpolated between its (coarse,
    // ~200 ms) position events so the jaw follows 50 ms envelope frames.
    var pos = Duration.zero;
    final since = Stopwatch();
    void sample(Duration t) {
      if (_disposed || env == null) return;
      // >= 0.02 keeps the rig in its audio-driven mouth state while the
      // clip plays, even through quiet frames.
      voiceLevel.value = math.max(0.02, env.at(t));
    }

    final tick = env == null
        ? null
        : Timer.periodic(const Duration(milliseconds: 50), (_) {
            if (since.isRunning) sample(pos + since.elapsed);
          });
    try {
      await _s.clipPlayer.play(
        Uint8List.fromList(clip.bytes),
        mimeType: clip.mimeType,
        onPosition: env == null
            ? null
            : (p) {
                pos = p;
                since
                  ..reset()
                  ..start();
                sample(p);
              },
      );
    } catch (_) {
      // Playback failure: the coaching text is still on screen.
    } finally {
      tick?.cancel();
      if (!_disposed) voiceLevel.value = null;
    }
  }

  Future<void> _stopVoices() async {
    await _s.speechOut.stop();
    await _s.clipPlayer.stop();
  }

  /// Interrupts the Professor (barge-in) and returns to the learner's turn.
  Future<void> interrupt() async {
    if (state != TutorState.speaking) return;
    _epoch++;
    await _stopVoices();
    _set(TutorState.idle);
  }

  // ---------- Learning artefacts ----------

  /// Saves a corrected sentence to My Words (source: tutor).
  Future<void> saveCorrection(String sentence) async {
    if (savedCorrections.contains(sentence)) return;
    final now = _progress.now.toUtc();
    await _s.vocabulary.save(
      VocabularyEntry(
        id: newLocalId(),
        learnerId: _progress.profile.id,
        originalExpression: sentence,
        translations: const {},
        contextualMeaning: const {},
        contextLine: sentence,
        source: VocabularySource.tutor,
        sourceContentId: context.contentId,
        sourceContentTitle: context.contentTitle,
        createdAt: now,
        updatedAt: now,
        nextReviewAt: now,
      ),
    );
    savedCorrections.add(sentence);
    _s.analytics.log(AnalyticsEvent.vocabularySaved, {'source': 'tutor'});
    notifyListeners();
  }

  Set<String> get usedExpressions => {
    for (final t in turns) ...t.usedExpressions,
  };

  List<String> get corrections => [
    for (final t in turns)
      if (t.feedback?.suggestion != null) t.feedback!.suggestion!,
  ];

  int get repeatsPassed =>
      turns.where((t) => t.repeatScore?.passed ?? false).length;
  int get repeatsTried => turns.where((t) => t.repeatScore != null).length;

  /// Ends the conversation; awards XP through the progress service only
  /// for a real conversation (>= [minLearnerTurnsForXp] English turns).
  Future<ActivityReward?> end() async {
    _epoch++;
    _autoRetry?.cancel();
    await _s.speechIn.cancel();
    await _s.recorder.cancel();
    await _stopVoices();
    if (learnerTurns >= minLearnerTurnsForXp && reward == null) {
      reward = await _progress.completeActivity(
        LearningActivity(
          id: 'tutor:${context.contentId ?? 'free'}',
          type: ActivityType.tutorConversation,
          contentId: context.contentId,
          native: context.native,
        ),
      );
      await _s.conversations.save(
        ConversationSession(
          id: sessionId,
          tutorCharacterId: 'professor',
          native: context.native,
          contentId: context.contentId,
          createdAt: _progress.now.toUtc(),
          learnerTurns: learnerTurns,
          usedExpressions: usedExpressions.toList(),
          suggestions: corrections,
        ),
      );
      _s.analytics.log(AnalyticsEvent.tutorSessionCompleted, {
        'learnerTurns': learnerTurns,
      });
    }
    _set(TutorState.ended);
    return reward;
  }

  @override
  void dispose() {
    _disposed = true;
    _endpoint?.cancel();
    _autoRetry?.cancel();
    unawaited(_levelSub?.cancel());
    level.dispose();
    voiceLevel.dispose();
    unawaited(_s.speechIn.cancel());
    unawaited(_s.recorder.cancel());
    unawaited(_stopVoices());
    super.dispose();
  }
}
