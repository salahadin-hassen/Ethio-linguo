import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/app_controller.dart';
import '../../app/app_services.dart';
import '../../core/util/local_id.dart';
import '../../data/models/activity.dart';
import '../../data/models/conversation.dart';
import '../../data/models/language.dart';
import '../../services/analytics/analytics.dart';
import '../../services/speech/speech_services.dart';
import '../../services/tutor/tutor_engine.dart';

/// States the Speak UI renders. Every state has a distinct visual.
enum TutorState {
  idle,
  connecting,
  listening,
  thinking,
  speaking,
  ended,

  /// No live tutor (offline, relay down, no credentials). Honest fallback.
  unavailable,
  error,
}

/// Orchestrates speech-in -> tutor engine -> speech-out. Depends only on
/// provider-independent interfaces; owns no plugin or HTTP code.
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
  bool voiceOutput = false;
  int _failures = 0;
  bool _disposed = false;
  RecognizedSpeech? _last;
  ActivityReward? reward;

  int get learnerTurns =>
      turns.where((t) => t.speaker == Speaker.learner).length;
  bool get canTalk => state == TutorState.idle;

  void _set(TutorState s, {String? msg}) {
    state = s;
    message = msg;
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    _set(TutorState.connecting);
    final a = await _s.tutor.availability();
    if (_disposed) return;
    if (!a.live) {
      _set(TutorState.unavailable, msg: a.reason);
      return;
    }
    voiceOutput = await _s.speechOut.initialize();
    _s.analytics.log(AnalyticsEvent.tutorSessionStarted, {
      'withLesson': context.hasLesson,
    });
    await _exchange(null, null);
  }

  Future<void> startListening() async {
    if (!canTalk) return;
    if (!_s.speechIn.available && !await _s.speechIn.initialize()) {
      micAvailable = false;
      _set(
        TutorState.idle,
        msg: 'Microphone or speech recognition is unavailable. Type instead.',
      );
      return;
    }
    await _s.speechOut.stop();
    partial = '';
    _last = null;
    _set(TutorState.listening);
    await _s.speechIn.listen(
      localeId: Languages.en.speechLocale!,
      onResult: (r) {
        _last = r;
        partial = r.text;
        if (r.isFinal && state == TutorState.listening) {
          unawaited(_submit(r.text, r.confidence));
        } else if (!_disposed) {
          notifyListeners();
        }
      },
    );
  }

  Future<void> stopListening() async {
    if (state != TutorState.listening) return;
    await _s.speechIn.stop();
    // Some engines deliver the final result after stop(); give them a beat.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (state == TutorState.listening) {
      final text = _last?.text ?? partial;
      if (text.trim().isEmpty) {
        _set(
          TutorState.idle,
          msg: 'I didn\'t catch that. Hold the button and speak.',
        );
      } else {
        await _submit(text, _last?.confidence);
      }
    }
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty || !canTalk) return;
    await _submit(text.trim(), null);
  }

  Future<void> retry() async {
    if (state != TutorState.error) return;
    final lastLearner = turns.lastWhere(
      (t) => t.speaker == Speaker.learner,
      orElse: () => const TutorTurn(speaker: Speaker.learner, text: ''),
    );
    if (lastLearner.text.isEmpty) {
      await _exchange(null, null);
    } else {
      turns.remove(lastLearner);
      await _submit(lastLearner.text, lastLearner.sttConfidence);
    }
  }

  Future<void> _submit(String text, double? confidence) async {
    turns.add(
      TutorTurn(
        speaker: Speaker.learner,
        text: text,
        sttConfidence: confidence,
      ),
    );
    partial = '';
    await _exchange(text, confidence);
  }

  Future<void> _exchange(String? utterance, double? confidence) async {
    _set(TutorState.thinking);
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
        ),
      );
    } on TutorException catch (e) {
      _failures++;
      _set(
        _failures >= 2 || e.code == TutorErrorCode.unavailable
            ? TutorState.unavailable
            : TutorState.error,
        msg: e.message,
      );
      return;
    }
    if (_disposed) return;
    _failures = 0;
    if (utterance != null &&
        (r.feedback != null || r.usedExpressions.isNotEmpty)) {
      final i = turns.length - 1;
      final t = turns[i];
      turns[i] = TutorTurn(
        speaker: t.speaker,
        text: t.text,
        sttConfidence: t.sttConfidence,
        feedback: r.feedback,
        usedExpressions: r.usedExpressions,
      );
    }
    turns.add(
      TutorTurn(
        speaker: Speaker.tutor,
        text: r.replyText,
        translation: r.replyTranslation,
      ),
    );
    if (voiceOutput) {
      _set(TutorState.speaking);
      await _s.speechOut.speak(
        r.replyText,
        localeId: Languages.en.speechLocale!,
      );
    }
    if (_disposed) return;
    _set(r.done ? TutorState.ended : TutorState.idle);
  }

  Set<String> get usedExpressions => {
    for (final t in turns) ...t.usedExpressions,
  };

  /// Ends the conversation; awards XP through the progress service only
  /// for a real conversation (>= [minLearnerTurnsForXp] learner turns).
  Future<ActivityReward?> end() async {
    await _s.speechIn.cancel();
    await _s.speechOut.stop();
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
          suggestions: [
            for (final t in turns)
              if (t.feedback?.suggestion != null) t.feedback!.suggestion!,
          ],
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
    unawaited(_s.speechIn.cancel());
    unawaited(_s.speechOut.stop());
    super.dispose();
  }
}
