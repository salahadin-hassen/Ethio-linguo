import 'package:flutter/foundation.dart';

import '../characters.dart';
import 'rig_contract.dart';

/// App-facing character API. Business logic calls meaningful methods
/// (setListening, celebrate, reactToTap…); the Rive asset owns all motion.
/// Flutter never moves bones. A binding (RiveCharacter) mirrors this state
/// into the state machine; without a rig asset nothing is animated (see
/// CHARACTER_RIG_SPEC.md — no fake motion).
class CharacterRigController extends ChangeNotifier {
  bool listening = false;
  bool thinking = false;
  bool speaking = false;
  bool happy = false;
  RigEmotion emotion = RigEmotion.neutral;
  double gazeX = 0, gazeY = 0;

  /// Real audio level of the CURRENT playback (0..1) when a source provides
  /// it; null means "speaking, amplitude unknown" -> the rig's authored
  /// speech loop drives the mouth. Never synthesised here.
  double? voiceAmplitude;
  int idleVariant = 0;

  final List<String> _pendingTriggers = [];

  /// Triggers fired since the binding last drained them.
  List<String> drainTriggers() {
    final t = List<String>.of(_pendingTriggers);
    _pendingTriggers.clear();
    return t;
  }

  void _fire(String trigger) {
    _pendingTriggers.add(trigger);
    notifyListeners();
  }

  void setListening(bool on) => _set(() => listening = on);
  void setThinking(bool on) => _set(() => thinking = on);
  void setSpeaking(bool on, {double? amplitude}) => _set(() {
    speaking = on;
    voiceAmplitude = on ? amplitude : null;
  });
  void setVoiceAmplitude(double? a) => _set(() => voiceAmplitude = a);
  void setEmotion(RigEmotion e) => _set(() => emotion = e);
  void lookAt(double x, double y) => _set(() {
    gazeX = x.clamp(-1.0, 1.0);
    gazeY = y.clamp(-1.0, 1.0);
  });
  void setIdleVariant(int v) => _set(() => idleVariant = v % 3);

  void celebrate() => _fire(RigContract.celebrate);
  void wave() => _fire(RigContract.wave);
  void laugh() => _fire(RigContract.laugh);
  void correctAnswer() => _fire(RigContract.correctAnswer);
  void incorrectAnswer() => _fire(RigContract.incorrectAnswer);
  void achievementUnlocked() => _fire(RigContract.achievementUnlocked);
  void explain() => _fire(RigContract.explain);
  void nod() => _fire(RigContract.nod);
  void goodbye() => _fire(RigContract.goodbye);

  /// Tap at a normalised position inside the character (-1..1): the
  /// character looks there, then reacts (the rig varies the reaction).
  void reactToTap({double x = 0, double y = 0}) {
    lookAt(x, y);
    _fire(RigContract.tapReaction);
  }

  void returnToIdle() => _set(() {
    listening = thinking = speaking = happy = false;
    voiceAmplitude = null;
    emotion = RigEmotion.neutral;
    gazeX = gazeY = 0;
  });

  /// Maps an app-level character state (driven by real events) to rig
  /// inputs + the event trigger for the transition.
  void applyState(CharacterState s, {CharacterState? previous}) {
    final (emo, listen, think, isHappy) = switch (s) {
      CharacterState.idle => (RigEmotion.neutral, false, false, false),
      CharacterState.greeting ||
      CharacterState.waving => (RigEmotion.happy, false, false, true),
      CharacterState.curious => (RigEmotion.curious, false, false, false),
      CharacterState.happy ||
      CharacterState.approving => (RigEmotion.happy, false, false, true),
      CharacterState.excited ||
      CharacterState.celebrating => (RigEmotion.happy, false, false, true),
      CharacterState.thinking => (RigEmotion.thinking, false, true, false),
      CharacterState.transcribing => (RigEmotion.curious, true, false, false),
      CharacterState.confused ||
      CharacterState.surprised => (RigEmotion.surprised, false, false, false),
      CharacterState.encouraging || CharacterState.correcting => (
        RigEmotion.encouraging,
        false,
        false,
        false,
      ),
      CharacterState.sleeping => (RigEmotion.sleepy, false, false, false),
      CharacterState.listening => (RigEmotion.curious, true, false, false),
      CharacterState.speaking ||
      CharacterState.explaining => (RigEmotion.neutral, false, false, false),
    };
    emotion = emo;
    listening = listen;
    thinking = think;
    happy = isHappy;
    if (s != previous) {
      final trigger = switch (s) {
        CharacterState.greeting || CharacterState.waving => RigContract.wave,
        CharacterState.happy ||
        CharacterState.approving => RigContract.correctAnswer,
        CharacterState.excited ||
        CharacterState.celebrating => RigContract.celebrate,
        CharacterState.confused ||
        CharacterState.correcting => RigContract.incorrectAnswer,
        CharacterState.explaining => RigContract.explain,
        CharacterState.listening => RigContract.nod,
        _ when previous == CharacterState.sleeping => RigContract.wakeUp,
        _ => null,
      };
      if (trigger != null) _pendingTriggers.add(trigger);
    }
    notifyListeners();
  }

  void _set(VoidCallback f) {
    f();
    notifyListeners();
  }
}
