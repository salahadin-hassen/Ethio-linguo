/// Expressions supported by the mascot. Each maps to a combination of
/// eyes / brows / mouth / arm pose / prop in [MascotPainter].
enum MascotMood {
  welcome,
  happy,
  thinking,
  confused,
  encouraging,
  celebrating,
  sleeping,
  excited,
}

enum EyeStyle { open, happy, closed, wide, lookAside }

enum MouthStyle { smile, grin, open, small, wavy, soft, sleepy }

enum BrowStyle { neutral, raised, worried, quizzical, none }

enum ArmPose { rest, wave, bothUp, chin, shrug, thumbUp, hug }

enum MascotProp { none, sparkles, question, thoughtDots, zzz, heart, confetti }

class MoodSpec {
  const MoodSpec({
    required this.eyes,
    required this.mouth,
    required this.brows,
    required this.arms,
    this.prop = MascotProp.none,
    this.blush = false,
  });

  final EyeStyle eyes;
  final MouthStyle mouth;
  final BrowStyle brows;
  final ArmPose arms;
  final MascotProp prop;
  final bool blush;

  static MoodSpec of(MascotMood mood) => switch (mood) {
    MascotMood.welcome => const MoodSpec(
      eyes: EyeStyle.open,
      mouth: MouthStyle.grin,
      brows: BrowStyle.raised,
      arms: ArmPose.wave,
      blush: true,
    ),
    MascotMood.happy => const MoodSpec(
      eyes: EyeStyle.happy,
      mouth: MouthStyle.open,
      brows: BrowStyle.raised,
      arms: ArmPose.thumbUp,
      blush: true,
    ),
    MascotMood.thinking => const MoodSpec(
      eyes: EyeStyle.lookAside,
      mouth: MouthStyle.small,
      brows: BrowStyle.quizzical,
      arms: ArmPose.chin,
      prop: MascotProp.thoughtDots,
    ),
    MascotMood.confused => const MoodSpec(
      eyes: EyeStyle.open,
      mouth: MouthStyle.wavy,
      brows: BrowStyle.worried,
      arms: ArmPose.shrug,
      prop: MascotProp.question,
    ),
    MascotMood.encouraging => const MoodSpec(
      eyes: EyeStyle.happy,
      mouth: MouthStyle.soft,
      brows: BrowStyle.worried,
      arms: ArmPose.hug,
      prop: MascotProp.heart,
      blush: true,
    ),
    MascotMood.celebrating => const MoodSpec(
      eyes: EyeStyle.happy,
      mouth: MouthStyle.open,
      brows: BrowStyle.raised,
      arms: ArmPose.bothUp,
      prop: MascotProp.confetti,
      blush: true,
    ),
    MascotMood.sleeping => const MoodSpec(
      eyes: EyeStyle.closed,
      mouth: MouthStyle.sleepy,
      brows: BrowStyle.none,
      arms: ArmPose.hug,
      prop: MascotProp.zzz,
    ),
    MascotMood.excited => const MoodSpec(
      eyes: EyeStyle.wide,
      mouth: MouthStyle.open,
      brows: BrowStyle.raised,
      arms: ArmPose.bothUp,
      prop: MascotProp.sparkles,
      blush: true,
    ),
  };
}
