import 'mascot_mood.dart';

/// The human cast (animal concepts are intentionally not used).
enum CastMember {
  /// Elder teacher; the AI tutor in Speak.
  professor('The Professor', 'Your English teacher'),

  /// Energetic guide; welcomes and cheers.
  spark('Spark', 'Your learning buddy'),

  /// Thoughtful classmate; helps when things are unclear.
  wry('Wry', 'Your study partner'),

  /// Music-loving friend with a drum; celebrates wins.
  beat('Beat', 'Your rhythm coach');

  const CastMember(this.displayName, this.role);
  final String displayName;
  final String role;
}

/// Pose artwork available per cast member: `assets/characters/<member>/<pose>.png`.
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

/// Which cast member shows each app mood when a screen does not pick one.
(CastMember, CharacterPose) castForMood(MascotMood mood) => switch (mood) {
  MascotMood.welcome => (CastMember.spark, CharacterPose.speaking),
  MascotMood.happy => (CastMember.spark, CharacterPose.laughing),
  MascotMood.excited => (CastMember.spark, CharacterPose.excited),
  MascotMood.celebrating => (CastMember.beat, CharacterPose.celebrating),
  MascotMood.encouraging => (CastMember.wry, CharacterPose.correct),
  MascotMood.thinking => (CastMember.professor, CharacterPose.thinking),
  MascotMood.confused => (CastMember.wry, CharacterPose.confused),
  MascotMood.sleeping => (CastMember.wry, CharacterPose.idle),
};

/// The closest pose a given cast member has for a mood (used when a screen
/// pins one character, e.g. the Professor in Speak).
CharacterPose poseFor(CastMember m, MascotMood mood) {
  final wanted = switch (mood) {
    MascotMood.thinking => [
      CharacterPose.thinking,
      CharacterPose.confused,
      CharacterPose.listening,
    ],
    MascotMood.confused => [CharacterPose.confused, CharacterPose.thinking],
    MascotMood.celebrating => [
      CharacterPose.celebrating,
      CharacterPose.correct,
      CharacterPose.excited,
    ],
    MascotMood.encouraging || MascotMood.happy => [
      CharacterPose.correct,
      CharacterPose.laughing,
      CharacterPose.celebrating,
    ],
    MascotMood.excited => [
      CharacterPose.excited,
      CharacterPose.listening,
      CharacterPose.teaching,
    ],
    MascotMood.sleeping => [
      CharacterPose.idle,
      CharacterPose.thinking,
      CharacterPose.listening,
    ],
    MascotMood.welcome => [CharacterPose.speaking, CharacterPose.teaching],
  };
  final have = availablePoses[m]!;
  for (final p in wanted) {
    if (have.contains(p)) return p;
  }
  return have.contains(CharacterPose.teaching)
      ? CharacterPose.teaching
      : have.first;
}
