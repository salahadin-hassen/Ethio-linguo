import '../rig/rig_contract.dart';
import 'puppet_motor.dart';

// Behaviour of each code-rigged character: rest pose, emotions and an
// authored gesture library. Every gesture has anticipation -> action ->
// follow-through -> recovery (keys at the start/end return to rest).

const _relaxed = <Ch, double>{
  Ch.armLUp: 0.14,
  Ch.armLLow: 0.18,
  Ch.armRUp: 0.14,
  Ch.armRLow: 0.18,
  Ch.mouthSmile: 0.25,
};

Map<Ch, double> _emotion(RigEmotion e) => switch (e) {
  RigEmotion.neutral => const {Ch.mouthSmile: 0.25},
  RigEmotion.happy => const {
    Ch.mouthSmile: 0.95,
    Ch.cheek: 0.8,
    Ch.browL: 0.35,
    Ch.browR: 0.35,
  },
  RigEmotion.curious => const {
    Ch.browL: 0.7,
    Ch.browR: 0.15,
    Ch.headRot: 0.09,
    Ch.mouthRound: 0.25,
    Ch.mouthSmile: 0.1,
  },
  RigEmotion.thinking => const {
    Ch.browFurrow: 0.55,
    Ch.browL: 0.2,
    Ch.mouthSmile: -0.15,
    Ch.headRot: -0.07,
  },
  RigEmotion.surprised => const {
    Ch.browL: 1,
    Ch.browR: 1,
    Ch.mouthOpen: 0.45,
    Ch.mouthRound: 0.85,
    Ch.lidWide: 0.8,
  },
  RigEmotion.encouraging => const {
    Ch.mouthSmile: 0.7,
    Ch.browL: 0.4,
    Ch.browR: 0.4,
    Ch.cheek: 0.4,
    Ch.headRot: -0.05,
  },
  RigEmotion.disappointed => const {
    Ch.browFurrow: -0.6,
    Ch.mouthSmile: -0.35,
    Ch.headNod: 0.25,
  },
  RigEmotion.sleepy => const {
    Ch.headNod: 0.45,
    Ch.headRot: 0.12,
    Ch.mouthSmile: 0.05,
    Ch.torsoLean: 0.03,
  },
};

const _r = {
  Ch.armLUp: 0.14,
  Ch.armLLow: 0.18,
  Ch.armRUp: 0.14,
  Ch.armRLow: 0.18,
};

/// Spark: upbeat companion — bigger, quicker, more playful actions.
class SparkSpec extends PuppetSpec {
  @override
  Map<Ch, double> rest() => _relaxed;
  @override
  Map<Ch, double> emotion(RigEmotion e) => _emotion(e);

  @override
  Map<Ch, double> thinkingPose() => const {
    Ch.armRUp: -0.6,
    Ch.armRLow: 4.0,
    Ch.headRot: -0.08,
  };
  @override
  (Hand?, Hand?) thinkingHands() => (null, Hand.chin);

  static const wave = Gesture(
    'wave',
    1.6,
    [
      (0, _r),
      (
        0.15,
        {
          Ch.armRUp: 2.0,
          Ch.armRLow: 0.2,
          Ch.shoulderR: 0.6,
          Ch.mouthSmile: 0.9,
          Ch.headRot: -0.06,
        },
      ),
      (0.3, {Ch.armRUp: 2.35, Ch.armRLow: 0.85}),
      (0.45, {Ch.armRUp: 2.35, Ch.armRLow: 0.2}),
      (0.6, {Ch.armRUp: 2.35, Ch.armRLow: 0.85}),
      (0.75, {Ch.armRUp: 2.3, Ch.armRLow: 0.3, Ch.mouthSmile: 0.9}),
      (1, _r),
    ],
    hands: [(0.1, null, Hand.open), (0.9, null, Hand.relaxed)],
  );

  static const celebrate = Gesture(
    'celebrate',
    1.8,
    [
      (0, _r),
      (
        0.1,
        {
          Ch.kneeBend: 0.8,
          Ch.armLUp: 0.05,
          Ch.armRUp: 0.05,
          Ch.headNod: 0.2,
          Ch.mouthSmile: 0.6,
        },
      ), // anticipation
      (
        0.25,
        {
          Ch.kneeBend: 0,
          Ch.armLUp: 2.7,
          Ch.armRUp: 2.7,
          Ch.armLLow: 0.3,
          Ch.armRLow: 0.3,
          Ch.headNod: -0.3,
          Ch.mouthOpen: 0.6,
          Ch.mouthSmile: 1,
          Ch.eyeHappy: 1,
          Ch.cheek: 1,
        },
      ),
      (
        0.4,
        {Ch.hipShift: 6, Ch.headRot: 0.12, Ch.kneeBend: 0.4, Ch.armLLow: 0.8},
      ),
      (
        0.55,
        {
          Ch.hipShift: -6,
          Ch.headRot: -0.12,
          Ch.kneeBend: 0,
          Ch.armRLow: 0.8,
          Ch.armLLow: 0.3,
        },
      ),
      (
        0.7,
        {
          Ch.hipShift: 6,
          Ch.headRot: 0.1,
          Ch.kneeBend: 0.4,
          Ch.armLLow: 0.8,
          Ch.armRLow: 0.3,
        },
      ),
      (
        0.85,
        {
          Ch.hipShift: 0,
          Ch.headRot: 0,
          Ch.kneeBend: 0.1,
          Ch.armLUp: 1.2,
          Ch.armRUp: 1.2,
          Ch.eyeHappy: 0.6,
          Ch.mouthOpen: 0.2,
        },
      ),
      (1, _r),
    ],
    hands: [(0.2, Hand.fist, Hand.fist), (0.9, Hand.relaxed, Hand.relaxed)],
  );

  static const laugh = Gesture(
    'laugh',
    1.3,
    [
      (0, _r),
      (
        0.15,
        {
          Ch.headNod: -0.25,
          Ch.eyeHappy: 1,
          Ch.mouthOpen: 0.7,
          Ch.mouthSmile: 1,
          Ch.cheek: 1,
          Ch.shoulderL: 0.8,
          Ch.shoulderR: 0.8,
        },
      ),
      (
        0.3,
        {
          Ch.mouthOpen: 0.4,
          Ch.shoulderL: 0.3,
          Ch.shoulderR: 0.3,
          Ch.torsoLean: -0.04,
        },
      ),
      (0.45, {Ch.mouthOpen: 0.75, Ch.shoulderL: 0.9, Ch.shoulderR: 0.9}),
      (
        0.6,
        {
          Ch.mouthOpen: 0.4,
          Ch.shoulderL: 0.3,
          Ch.shoulderR: 0.3,
          Ch.torsoLean: 0.04,
          Ch.armLUp: 0.4,
          Ch.armLLow: 1.6,
        },
      ),
      (0.8, {Ch.mouthOpen: 0.25, Ch.eyeHappy: 0.6}),
      (1, _r),
    ],
    hands: [(0.5, Hand.open, null), (0.9, Hand.relaxed, null)],
  );

  static const correct = Gesture(
    'correct',
    1.1,
    [
      (0, _r),
      (
        0.15,
        {
          Ch.armRUp: 0.05,
          Ch.armRLow: 0.4,
          Ch.kneeBend: 0.3,
          Ch.mouthSmile: 0.5,
        },
      ), // wind-up
      (
        0.4,
        {
          Ch.armRUp: 2.25,
          Ch.armRLow: 0.55,
          Ch.kneeBend: 0,
          Ch.mouthSmile: 1,
          Ch.cheek: 0.9,
          Ch.browL: 0.5,
          Ch.browR: 0.5,
          Ch.headNod: -0.15,
        },
      ),
      (0.6, {Ch.armRUp: 2.1, Ch.armRLow: 0.7, Ch.headNod: 0.05}),
      (1, _r),
    ],
    hands: [(0.3, null, Hand.fist), (0.9, null, Hand.relaxed)],
  );

  static const incorrect = Gesture(
    'incorrect',
    1.5,
    [
      (0, _r),
      (
        0.15,
        {
          Ch.browL: 0.9,
          Ch.browR: 0.9,
          Ch.mouthRound: 0.7,
          Ch.mouthOpen: 0.3,
          Ch.lidWide: 0.6,
          Ch.torsoLean: -0.03,
        },
      ), // small surprise
      (
        0.4,
        {
          Ch.browFurrow: -0.3,
          Ch.mouthOpen: 0,
          Ch.mouthRound: 0,
          Ch.mouthSmile: 0.55,
          Ch.armLUp: 0.7,
          Ch.armLLow: 1.0,
          Ch.headRot: -0.08,
        },
      ), // reassuring palm
      (
        0.75,
        {
          Ch.armLUp: 0.65,
          Ch.armLLow: 1.1,
          Ch.mouthSmile: 0.7,
          Ch.browL: 0.4,
          Ch.browR: 0.4,
        },
      ),
      (1, _r),
    ],
    hands: [(0.3, Hand.open, null), (0.9, Hand.relaxed, null)],
  );

  static const thumbs = Gesture(
    'thumbs',
    1.4,
    [
      (0, _r),
      (
        0.15,
        {Ch.headRot: 0.14, Ch.browL: 0.7, Ch.mouthRound: 0.3},
      ), // curious tilt
      (
        0.45,
        {
          Ch.armRUp: 0.55,
          Ch.armRLow: 1.9,
          Ch.headRot: 0.05,
          Ch.mouthSmile: 0.9,
          Ch.mouthRound: 0,
          Ch.cheek: 0.6,
        },
      ),
      (0.75, {Ch.armRUp: 0.5, Ch.armRLow: 2.0}),
      (1, _r),
    ],
    hands: [(0.3, null, Hand.thumb), (0.9, null, Hand.relaxed)],
  );

  static const surpriseGiggle = Gesture('surpriseGiggle', 1.5, [
    (0, _r),
    (
      0.12,
      {
        Ch.browL: 1,
        Ch.browR: 1,
        Ch.lidWide: 0.9,
        Ch.mouthRound: 0.9,
        Ch.mouthOpen: 0.4,
        Ch.torsoLean: -0.05,
        Ch.shoulderL: 0.7,
        Ch.shoulderR: 0.7,
      },
    ),
    (
      0.4,
      {
        Ch.eyeHappy: 1,
        Ch.mouthRound: 0,
        Ch.mouthOpen: 0.45,
        Ch.mouthSmile: 1,
        Ch.cheek: 1,
        Ch.lidWide: 0,
      },
    ),
    (0.55, {Ch.shoulderL: 0.2, Ch.shoulderR: 0.2, Ch.mouthOpen: 0.25}),
    (0.7, {Ch.shoulderL: 0.6, Ch.shoulderR: 0.6, Ch.mouthOpen: 0.45}),
    (1, _r),
  ]);

  static const wakeUp = Gesture(
    'wakeUp',
    1.8,
    [
      (0, {Ch.headNod: 0.4}),
      (
        0.3,
        {
          Ch.armLUp: 2.8,
          Ch.armRUp: 2.8,
          Ch.armLLow: 0.5,
          Ch.armRLow: 0.5,
          Ch.torsoLean: -0.04,
          Ch.mouthOpen: 0.7,
          Ch.mouthRound: 0.6,
          Ch.eyeHappy: 1,
        },
      ), // stretch + yawn
      (0.65, {Ch.armLUp: 2.6, Ch.armRUp: 2.6, Ch.mouthOpen: 0.1}),
      (1, _r),
    ],
    hands: [(0.2, Hand.fist, Hand.fist), (0.85, Hand.relaxed, Hand.relaxed)],
  );

  @override
  Gesture? gesture(String trigger, int variant) => switch (trigger) {
    RigContract.wave => wave,
    RigContract.celebrate || RigContract.achievementUnlocked => celebrate,
    RigContract.laugh => laugh,
    RigContract.correctAnswer => correct,
    RigContract.incorrectAnswer => incorrect,
    RigContract.wakeUp => wakeUp,
    RigContract.tapReaction => switch (variant % 3) {
      0 => surpriseGiggle,
      1 => wave,
      _ => thumbs,
    },
    _ => null,
  };

  @override
  Gesture idleGesture(int variant) => switch (variant) {
    // A: natural rest — weight shift, small adjustment.
    0 => const Gesture('idleA', 3.2, [
      (0, _r),
      (
        0.3,
        {
          Ch.hipShift: 4,
          Ch.torsoLean: 0.025,
          Ch.headRot: -0.04,
          Ch.shoulderL: 0.3,
        },
      ),
      (0.7, {Ch.hipShift: 3, Ch.torsoLean: 0.02, Ch.headRot: -0.03}),
      (1, _r),
    ]),
    // B: curious observation — brows + head turn toward something.
    1 => const Gesture('idleB', 3.0, [
      (0, _r),
      (
        0.25,
        {Ch.browL: 0.6, Ch.browR: 0.2, Ch.headRot: 0.07, Ch.mouthRound: 0.3},
      ),
      (
        0.7,
        {
          Ch.browL: 0.4,
          Ch.headRot: 0.05,
          Ch.mouthRound: 0.1,
          Ch.mouthSmile: 0.4,
        },
      ),
      (1, _r),
    ]),
    // C: playful — smile + tiny shrug.
    _ => const Gesture(
      'idleC',
      2.4,
      [
        (0, _r),
        (
          0.25,
          {
            Ch.mouthSmile: 0.9,
            Ch.cheek: 0.6,
            Ch.shoulderL: 0.9,
            Ch.shoulderR: 0.9,
            Ch.headRot: 0.08,
            Ch.armLUp: 0.35,
            Ch.armRUp: 0.35,
            Ch.armLLow: 0.6,
            Ch.armRLow: 0.6,
          },
        ),
        (0.5, {Ch.shoulderL: 0.1, Ch.shoulderR: 0.1}),
        (0.75, {Ch.mouthSmile: 0.7}),
        (1, _r),
      ],
      hands: [(0.2, Hand.open, Hand.open), (0.8, Hand.relaxed, Hand.relaxed)],
    ),
  };
}

/// The Professor: measured, warm teacher — slower, clearer gestures.
class ProfessorSpec extends PuppetSpec {
  @override
  Map<Ch, double> rest() => _relaxed;
  @override
  Map<Ch, double> emotion(RigEmotion e) => _emotion(e);

  @override
  Map<Ch, double> listeningPose() => const {
    Ch.torsoLean: 0.07,
    Ch.headNod: 0.12,
    Ch.headRot: -0.05,
    Ch.browL: 0.3,
    Ch.browR: 0.2,
    Ch.mouthSmile: 0.35,
  };

  @override
  Map<Ch, double> thinkingPose() => const {
    Ch.armRUp: -0.6,
    Ch.armRLow: 4.0,
    Ch.headRot: -0.09,
    Ch.torsoLean: -0.02,
  };
  @override
  (Hand?, Hand?) thinkingHands() => (null, Hand.chin);

  static const explain = Gesture(
    'explain',
    2.2,
    [
      (0, _r),
      (0.12, {Ch.armRUp: 0.3, Ch.armRLow: 0.6}), // anticipation
      (
        0.35,
        {
          Ch.armRUp: 1.15,
          Ch.armRLow: 1.25,
          Ch.headRot: -0.06,
          Ch.headNod: -0.1,
          Ch.browL: 0.5,
          Ch.browR: 0.5,
        },
      ),
      (
        0.55,
        {Ch.armRUp: 1.25, Ch.armRLow: 1.0, Ch.headRot: 0.04, Ch.headNod: 0.1},
      ), // emphasis
      (0.75, {Ch.armRUp: 1.1, Ch.armRLow: 1.3, Ch.headNod: 0}),
      (1, _r),
    ],
    hands: [(0.2, null, Hand.open), (0.9, null, Hand.relaxed)],
  );

  static const point = Gesture(
    'point',
    1.8,
    [
      (0, _r),
      (0.15, {Ch.armRUp: 0.6, Ch.armRLow: 0.9, Ch.headTurn: 0.4}),
      (
        0.4,
        {
          Ch.armRUp: 1.85,
          Ch.armRLow: 0.15,
          Ch.headTurn: 0.6,
          Ch.pupilX: 0.9,
          Ch.browL: 0.5,
        },
      ),
      (
        0.7,
        {
          Ch.armRUp: 1.8,
          Ch.armRLow: 0.2,
          Ch.headTurn: 0.2,
          Ch.pupilX: 0,
          Ch.mouthSmile: 0.5,
        },
      ),
      (1, _r),
    ],
    hands: [(0.25, null, Hand.point), (0.9, null, Hand.relaxed)],
  );

  static const correcting = Gesture(
    'correcting',
    2.2,
    [
      (0, _r),
      (
        0.15,
        {Ch.browFurrow: -0.3, Ch.headRot: 0.06, Ch.mouthSmile: 0.3},
      ), // supportive face first
      (
        0.35,
        {Ch.armRUp: 0.75, Ch.armRLow: 1.85, Ch.headNod: 0.1},
      ), // one gentle finger
      (
        0.6,
        {
          Ch.armRUp: 0.9,
          Ch.armRLow: 1.2,
          Ch.headNod: -0.05,
          Ch.mouthSmile: 0.6,
          Ch.browL: 0.4,
          Ch.browR: 0.4,
        },
      ), // inviting open palm
      (1, _r),
    ],
    hands: [
      (0.25, null, Hand.point),
      (0.5, null, Hand.open),
      (0.92, null, Hand.relaxed),
    ],
  );

  static const approve = Gesture(
    'approve',
    1.6,
    [
      (0, _r),
      (
        0.2,
        {
          Ch.headNod: 0.25,
          Ch.mouthSmile: 0.95,
          Ch.cheek: 0.8,
          Ch.browL: 0.5,
          Ch.browR: 0.5,
        },
      ),
      (0.4, {Ch.headNod: -0.1, Ch.armRUp: 0.55, Ch.armRLow: 1.9}),
      (0.55, {Ch.headNod: 0.2}),
      (0.75, {Ch.headNod: 0, Ch.armRUp: 0.5, Ch.armRLow: 2.0}),
      (1, _r),
    ],
    hands: [(0.3, null, Hand.thumb), (0.9, null, Hand.relaxed)],
  );

  static const congratulate = Gesture(
    'congratulate',
    2.0,
    [
      (0, _r),
      (
        0.12,
        {
          Ch.mouthSmile: 1,
          Ch.eyeHappy: 1,
          Ch.cheek: 1,
          Ch.armLUp: -0.2,
          Ch.armRUp: -0.2,
          Ch.armLLow: -0.6,
          Ch.armRLow: -0.6,
        },
      ),
      (0.25, {Ch.armLLow: -0.85, Ch.armRLow: -0.85, Ch.headNod: -0.1}), // clap
      (0.38, {Ch.armLLow: -0.55, Ch.armRLow: -0.55}),
      (0.5, {Ch.armLLow: -0.85, Ch.armRLow: -0.85, Ch.headNod: 0.05}),
      (0.62, {Ch.armLLow: -0.55, Ch.armRLow: -0.55}),
      (0.74, {Ch.armLLow: -0.85, Ch.armRLow: -0.85, Ch.mouthOpen: 0.4}),
      (1, _r),
    ],
    hands: [(0.1, Hand.open, Hand.open), (0.9, Hand.relaxed, Hand.relaxed)],
  );

  static const laugh = Gesture(
    'laugh',
    1.6,
    [
      (0, _r),
      (
        0.2,
        {
          Ch.headNod: -0.2,
          Ch.eyeHappy: 1,
          Ch.mouthOpen: 0.6,
          Ch.mouthSmile: 1,
          Ch.cheek: 1,
          Ch.armLUp: -0.1,
          Ch.armLLow: -0.4,
        },
      ),
      (0.4, {Ch.mouthOpen: 0.3, Ch.shoulderL: 0.6, Ch.shoulderR: 0.6}),
      (0.6, {Ch.mouthOpen: 0.55, Ch.shoulderL: 0.1, Ch.shoulderR: 0.1}),
      (1, _r),
    ],
    hands: [(0.15, Hand.open, null), (0.9, Hand.relaxed, null)],
  );

  static const surprised = Gesture(
    'surprised',
    1.2,
    [
      (0, _r),
      (
        0.15,
        {
          Ch.browL: 1,
          Ch.browR: 1,
          Ch.lidWide: 1,
          Ch.mouthRound: 0.9,
          Ch.mouthOpen: 0.5,
          Ch.torsoLean: -0.06,
          Ch.armLUp: 0.5,
          Ch.armLLow: 0.9,
        },
      ),
      (
        0.6,
        {
          Ch.browL: 0.6,
          Ch.browR: 0.6,
          Ch.mouthOpen: 0.1,
          Ch.mouthSmile: 0.6,
          Ch.lidWide: 0.2,
        },
      ),
      (1, _r),
    ],
    hands: [(0.1, Hand.open, null), (0.85, Hand.relaxed, null)],
  );

  static const goodbye = Gesture(
    'goodbye',
    1.8,
    [
      (0, _r),
      (
        0.2,
        {
          Ch.armRUp: 2.2,
          Ch.armRLow: 0.3,
          Ch.mouthSmile: 0.9,
          Ch.headRot: -0.05,
        },
      ),
      (0.4, {Ch.armRLow: 0.8}),
      (0.6, {Ch.armRLow: 0.3}),
      (0.8, {Ch.armRLow: 0.7, Ch.headNod: 0.15}),
      (1, _r),
    ],
    hands: [(0.15, null, Hand.open), (0.9, null, Hand.relaxed)],
  );

  static const nod = Gesture('nod', 0.9, [
    (0, {}),
    (0.35, {Ch.headNod: 0.35, Ch.mouthSmile: 0.45}),
    (0.7, {Ch.headNod: -0.05}),
    (1, {}),
  ]);

  @override
  Gesture? gesture(String trigger, int variant) => switch (trigger) {
    RigContract.explain => explain,
    RigContract.pointToExample => point,
    RigContract.correctAnswer => approve,
    RigContract.incorrectAnswer => correcting,
    RigContract.celebrate || RigContract.achievementUnlocked => congratulate,
    RigContract.laugh => laugh,
    RigContract.wave || RigContract.goodbye => goodbye,
    RigContract.nod => nod,
    RigContract.wakeUp => surprised,
    RigContract.tapReaction => switch (variant % 3) {
      0 => surprised,
      1 => laugh,
      _ => approve,
    },
    _ => null,
  };

  /// While speaking, the Professor gestures with the dialogue.
  @override
  Gesture? speakingGesture(int n) => switch (n % 3) {
    0 => explain,
    1 => point,
    _ => nod,
  };

  @override
  Gesture idleGesture(int variant) => switch (variant) {
    0 => const Gesture('idleA', 3.6, [
      (0, _r),
      (0.35, {Ch.hipShift: -3, Ch.torsoLean: -0.02, Ch.headRot: 0.04}),
      (0.75, {Ch.hipShift: -2, Ch.headRot: 0.03}),
      (1, _r),
    ]),
    1 => const Gesture('idleB', 3.2, [
      (0, _r),
      (
        0.3,
        {Ch.browL: 0.5, Ch.browR: 0.1, Ch.headRot: -0.06, Ch.mouthRound: 0.2},
      ),
      (0.7, {Ch.browL: 0.3, Ch.headRot: -0.04, Ch.mouthSmile: 0.4}),
      (1, _r),
    ]),
    // C: adjusts the glasses perched on his hair, small smile.
    _ => const Gesture(
      'idleC',
      2.6,
      [
        (0, _r),
        (
          0.3,
          {
            Ch.armRUp: 2.55,
            Ch.armRLow: 1.35,
            Ch.headNod: -0.1,
            Ch.mouthSmile: 0.6,
          },
        ),
        (0.55, {Ch.armRUp: 2.5, Ch.armRLow: 1.45}),
        (0.8, {Ch.mouthSmile: 0.7, Ch.cheek: 0.4}),
        (1, _r),
      ],
      hands: [(0.2, null, Hand.point), (0.85, null, Hand.relaxed)],
    ),
  };
}
