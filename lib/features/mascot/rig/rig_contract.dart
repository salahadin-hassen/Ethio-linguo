import '../characters.dart';

// THE CONTRACT between the character designer (Rive) and the app.
// docs/CHARACTER_RIG_SPEC.md is the human-readable version; names here are
// the single source of truth. Rename only together with the .riv files.

/// Emotion values sent through the `emotion` number input.
enum RigEmotion {
  neutral, // 0
  happy, // 1
  curious, // 2
  thinking, // 3
  surprised, // 4
  encouraging, // 5
  disappointed, // 6 gentle, never shaming
  sleepy, // 7
}

class RigSpec {
  const RigSpec({
    required this.asset,
    required this.artboard,
    required this.stateMachine,
  });
  final String asset;
  final String artboard;
  final String stateMachine;
}

abstract final class RigContract {
  /// Which cast members have a rig slot. Supporting cast reuses the
  /// pipeline later (CHARACTER_RIG_SPEC §8).
  static const specs = <CastMember, RigSpec>{
    CastMember.spark: RigSpec(
      asset: 'assets/brand/characters/companion/companion.riv',
      artboard: 'Companion',
      stateMachine: 'CompanionCharacter',
    ),
    CastMember.professor: RigSpec(
      asset: 'assets/brand/characters/professor/professor.riv',
      artboard: 'Professor',
      stateMachine: 'ProfessorCharacter',
    ),
  };

  // Number inputs
  static const emotion = 'emotion'; // RigEmotion index
  static const gazeX = 'gazeX'; // -1 (left) .. 1 (right)
  static const gazeY = 'gazeY'; // -1 (up) .. 1 (down)
  static const mouthOpen = 'mouthOpen'; // 0..1 (direct jaw override)
  static const voiceAmplitude = 'voiceAmplitude'; // 0..1, real audio level
  static const idleVariant =
      'idleVariant'; // 0=A rest, 1=B curious, 2=C playful

  // Boolean inputs
  static const isListening = 'isListening';
  static const isSpeaking = 'isSpeaking';
  static const isThinking = 'isThinking';
  static const isHappy = 'isHappy';
  static const reducedMotion = 'reducedMotion';

  // Triggers
  static const tapReaction = 'tapReaction';
  static const celebrate = 'celebrate';
  static const wave = 'wave';
  static const laugh = 'laugh';
  static const correctAnswer = 'correctAnswer';
  static const incorrectAnswer = 'incorrectAnswer';
  static const achievementUnlocked = 'achievementUnlocked';
  static const wakeUp = 'wakeUp';
  // Professor-only gesture triggers
  static const explain = 'explain';
  static const pointToExample = 'pointToExample';
  static const nod = 'nod';
  static const goodbye = 'goodbye';

  static const numbers = [
    emotion,
    gazeX,
    gazeY,
    mouthOpen,
    voiceAmplitude,
    idleVariant,
  ];
  static const booleans = [
    isListening,
    isSpeaking,
    isThinking,
    isHappy,
    reducedMotion,
  ];
  static const triggers = [
    tapReaction,
    celebrate,
    wave,
    laugh,
    correctAnswer,
    incorrectAnswer,
    achievementUnlocked,
    wakeUp,
    explain,
    pointToExample,
    nod,
    goodbye,
  ];
}
