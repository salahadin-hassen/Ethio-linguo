import 'mascot_mood.dart';

/// The human cast (animal concepts are intentionally not used).
enum CastMember {
  /// Elder teacher; the AI tutor in Speak.
  professor('The Professor', 'Your English teacher'),

  /// The learner's companion across the app.
  spark('Spark', 'Your learning buddy'),

  /// Thoughtful study partner; empty and "not yet" states.
  wry('Wry', 'Your study partner'),

  /// Music-loving friend with a drum; joins big celebrations.
  beat('Beat', 'Your rhythm coach');

  const CastMember(this.displayName, this.role);
  final String displayName;
  final String role;
}

/// Pose artwork: `assets/characters/<member>/<pose>.png`.
enum CharacterPose {
  teaching,
  thinking,
  correct,
  idle,
  confused,
  speaking,
  excited,
  laughing,
  listening,
  celebrating,
}

/// Behavioural states. Each state = a pose + a motion signature
/// (docs/INTERACTION_STATE_MAP.md). States are set from REAL app events.
enum CharacterState {
  idle,
  greeting,
  waving,
  curious,
  happy,
  excited,
  thinking,
  confused,
  encouraging,
  celebrating,
  sleeping,
  // Professor / voice states
  listening,
  transcribing,
  speaking,
  explaining,
  correcting,
  approving,
  surprised,
}

const Map<CastMember, Set<CharacterPose>> availablePoses = {
  CastMember.professor: {
    CharacterPose.teaching,
    CharacterPose.thinking,
    CharacterPose.correct,
  },
  CastMember.spark: {
    CharacterPose.speaking,
    CharacterPose.excited,
    CharacterPose.laughing,
  },
  CastMember.wry: {
    CharacterPose.idle,
    CharacterPose.confused,
    CharacterPose.correct,
  },
  CastMember.beat: {
    CharacterPose.listening,
    CharacterPose.speaking,
    CharacterPose.celebrating,
  },
};

String characterAsset(CastMember m, CharacterPose p) =>
    'assets/characters/${m.name}/${p.name}.png';

/// Best available pose for [state] on [m] (artwork is limited; motion
/// carries the rest of the expression).
CharacterPose poseForState(CastMember m, CharacterState state) {
  final wanted = switch (state) {
    CharacterState.idle || CharacterState.greeting || CharacterState.waving => [
      CharacterPose.idle,
      CharacterPose.speaking,
      CharacterPose.teaching,
      CharacterPose.listening,
    ],
    // Listening must look attentive, never "thinking" (the Professor's
    // thinking art carries a thought bubble).
    CharacterState.listening => [
      CharacterPose.listening,
      CharacterPose.correct,
      CharacterPose.idle,
      CharacterPose.speaking,
    ],
    CharacterState.curious => [
      CharacterPose.listening,
      CharacterPose.thinking,
      CharacterPose.speaking,
      CharacterPose.idle,
    ],
    CharacterState.thinking || CharacterState.transcribing => [
      CharacterPose.thinking,
      CharacterPose.confused,
      CharacterPose.listening,
      CharacterPose.speaking,
    ],
    CharacterState.confused || CharacterState.surprised => [
      CharacterPose.confused,
      CharacterPose.thinking,
      CharacterPose.speaking,
    ],
    CharacterState.speaking ||
    CharacterState.explaining ||
    CharacterState.correcting => [
      CharacterPose.teaching,
      CharacterPose.speaking,
      CharacterPose.correct,
    ],
    CharacterState.encouraging || CharacterState.approving => [
      CharacterPose.correct,
      CharacterPose.laughing,
      CharacterPose.speaking,
    ],
    CharacterState.happy => [
      CharacterPose.laughing,
      CharacterPose.correct,
      CharacterPose.celebrating,
    ],
    CharacterState.excited => [
      CharacterPose.excited,
      CharacterPose.celebrating,
      CharacterPose.correct,
    ],
    CharacterState.celebrating => [
      CharacterPose.celebrating,
      CharacterPose.excited,
      CharacterPose.correct,
    ],
    CharacterState.sleeping => [
      CharacterPose.idle,
      CharacterPose.thinking,
      CharacterPose.listening,
    ],
  };
  final have = availablePoses[m]!;
  for (final p in wanted) {
    if (have.contains(p)) return p;
  }
  return have.first;
}

/// Legacy mood -> (who, state). The companion is Spark everywhere; Wry
/// owns empty/"not yet" states; Beat joins big celebrations; the Professor
/// teaches. One identity per role keeps characters recognisable.
(CastMember, CharacterState) castForMood(MascotMood mood) => switch (mood) {
  MascotMood.welcome => (CastMember.spark, CharacterState.waving),
  MascotMood.happy => (CastMember.spark, CharacterState.happy),
  MascotMood.excited => (CastMember.spark, CharacterState.excited),
  MascotMood.encouraging => (CastMember.spark, CharacterState.encouraging),
  MascotMood.thinking => (CastMember.spark, CharacterState.thinking),
  MascotMood.confused => (CastMember.spark, CharacterState.confused),
  MascotMood.celebrating => (CastMember.beat, CharacterState.celebrating),
  MascotMood.sleeping => (CastMember.wry, CharacterState.sleeping),
};

CharacterState stateForMood(MascotMood mood) => castForMood(mood).$2;
