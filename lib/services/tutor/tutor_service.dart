import 'package:flutter/foundation.dart';

import '../../data/models/language.dart';

// SHARED CONTRACT — see docs/INTEGRATION_CONTRACTS.md §7.
// Implementation owner: Engineer 3 (AI tutor). The UI talks ONLY to these
// types, never to a provider SDK, so the provider can change.

/// What the learner just studied. Built by the media lesson and handed to
/// the Speak feature through AppRoutes.speak.
class TutorContext {
  const TutorContext({
    required this.native,
    this.mediaId,
    this.sceneSummary = '',
    this.targetExpressions = const [],
    this.learnerLevel = 1,
  });

  final NativeLanguage native;
  final String? mediaId;
  final String sceneSummary;

  /// English expressions the tutor should practise (e.g. the ones saved).
  final List<String> targetExpressions;
  final int learnerLevel;

  Map<String, Object?> toJson() => {
    'nativeLanguage': native.code,
    'mediaId': mediaId,
    'sceneSummary': sceneSummary,
    'targetExpressions': targetExpressions,
    'learnerLevel': learnerLevel,
  };
}

/// The states the Speak UI must render. Every state needs a visual.
enum TutorState {
  idle,
  connecting,
  listening,
  thinking,
  speaking,
  ended,

  /// No live tutor (offline, no backend, no credentials). Show the honest
  /// fallback; never imitate a live conversation.
  unavailable,
  error,
}

enum Speaker { learner, tutor }

/// Correction for the learner's last utterance.
class TutorFeedback {
  const TutorFeedback({
    required this.kind,
    required this.note,
    this.suggestion,
    this.noteNative,
  });

  /// "great", "grammar", "word_choice" or "pronunciation".
  final String kind;
  final String note;
  final String? suggestion;

  /// The same note in the learner's language, when the provider produced one.
  final String? noteNative;

  factory TutorFeedback.fromJson(Map<String, Object?> j) => TutorFeedback(
    kind: j['kind']! as String,
    note: j['note']! as String,
    suggestion: j['suggestion'] as String?,
    noteNative: j['noteNative'] as String?,
  );
}

/// One transcript line.
class TutorTurn {
  const TutorTurn({
    required this.speaker,
    required this.text,
    this.translation,
    this.feedback,
    this.usedExpressions = const [],
  });

  final Speaker speaker;

  /// English text (what was said / recognised).
  final String text;
  final String? translation;
  final TutorFeedback? feedback;

  /// Target expressions the learner used correctly in this turn.
  final List<String> usedExpressions;
}

/// Why the live tutor is unavailable, in a form the UI can show.
class TutorAvailability {
  const TutorAvailability.live() : live = true, reason = null;
  const TutorAvailability.unavailable(this.reason) : live = false;

  final bool live;
  final String? reason;
}

/// One conversation. Listen to [state] and [turns] to render the screen.
abstract class TutorSession {
  ValueListenable<TutorState> get state;
  ValueListenable<List<TutorTurn>> get turns;

  /// Human-readable error for [TutorState.error].
  String? get errorMessage;

  Future<void> start();

  /// Push-to-talk: begin capturing the microphone.
  Future<void> startListening();

  /// Push-to-talk released: send the utterance and get a reply.
  Future<void> stopListening();

  /// Typed fallback input (also used by tests).
  Future<void> sendText(String text);

  Future<void> end();
}

/// Entry point the app depends on. Swap implementations in main.dart.
abstract interface class TutorService {
  Future<TutorAvailability> availability();
  TutorSession open(TutorContext context);
}

/// Default until a live implementation lands: reports itself unavailable,
/// so the UI shows the honest fallback instead of a fake conversation.
class UnavailableTutorService implements TutorService {
  const UnavailableTutorService([
    this.reason = 'Live tutor is not connected in this build.',
  ]);

  final String reason;

  @override
  Future<TutorAvailability> availability() async =>
      TutorAvailability.unavailable(reason);

  @override
  TutorSession open(TutorContext context) => _UnavailableSession(reason);
}

class _UnavailableSession implements TutorSession {
  _UnavailableSession(this.errorMessage);

  @override
  final String? errorMessage;

  @override
  final ValueNotifier<TutorState> state = ValueNotifier(TutorState.unavailable);

  @override
  final ValueNotifier<List<TutorTurn>> turns = ValueNotifier(const []);

  @override
  Future<void> start() async {}
  @override
  Future<void> startListening() async {}
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> sendText(String text) async {}
  @override
  Future<void> end() async => state.value = TutorState.ended;
}
