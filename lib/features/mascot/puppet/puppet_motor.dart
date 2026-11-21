import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../rig/character_rig_controller.dart';
import '../rig/rig_contract.dart';

// INTERIM code rig (until the designer's Rive files land — see
// docs/CHARACTER_RIG_SPEC.md). Same contract as the Rive rig: it reads only
// CharacterRigController. All motion is per body part; the character as a
// whole never translates/scales/rotates.

/// Every articulated channel of a puppet.
enum Ch {
  headRot, // head roll (rad)
  headTurn, // -1..1 face turned left/right (feature parallax)
  headNod, // -1..1 down(+)/up(-)
  torsoLean, // rad, forward/back lean shown as side tilt
  hipShift, // design px, weight shift
  shoulderL,
  shoulderR, // shoulder raise 0..1
  armLUp,
  armLLow,
  armRUp,
  armRLow, // rad (upper from down, outward +; lower bend)
  browL,
  browR, // raise -1..1
  browFurrow, // inner brows down (+) / up (-)
  pupilX,
  pupilY, // -1..1
  mouthOpen, // 0..1
  mouthSmile, // -1..1
  mouthRound, // 0..1 ("O")
  cheek, // 0..1 lift / blush
  eyeHappy, // 0..1 squint arcs (laughing)
  lidWide, // 0..1 surprise widen
  kneeBend, // 0..1 (dance / anticipation)
  hair, // secondary follow-through (rad)
}

enum Hand { relaxed, open, point, thumb, fist, chin, wave }

/// Spring stiffness per channel: different speeds per body part produce
/// overlapping action (eyes lead, head follows, torso and hair lag).
const _stiff = <Ch, double>{
  Ch.pupilX: 420,
  Ch.pupilY: 420,
  Ch.browL: 160,
  Ch.browR: 160,
  Ch.browFurrow: 160,
  Ch.mouthOpen: 520,
  Ch.mouthSmile: 140,
  Ch.mouthRound: 260,
  Ch.cheek: 120,
  Ch.eyeHappy: 200,
  Ch.lidWide: 220,
  Ch.headRot: 90,
  Ch.headTurn: 80,
  Ch.headNod: 110,
  Ch.torsoLean: 45,
  Ch.hipShift: 30,
  Ch.shoulderL: 90,
  Ch.shoulderR: 90,
  Ch.armLUp: 75,
  Ch.armLLow: 95,
  Ch.armRUp: 75,
  Ch.armRLow: 95,
  Ch.kneeBend: 120,
  Ch.hair: 35,
};

class _Spring {
  double x = 0, v = 0;
  void step(double target, double k, double dt) {
    final c = 2 * math.sqrt(k) * 0.72; // slightly under-damped: settles alive
    final a = k * (target - x) - c * v;
    v += a * dt;
    x += v * dt;
  }
}

/// A keyframed action with anticipation, action, follow-through, recovery.
class Gesture {
  const Gesture(this.name, this.duration, this.keys, {this.hands = const []});
  final String name;
  final double duration; // seconds
  /// (time 0..1, channel values). Unlisted channels keep the base pose.
  final List<(double, Map<Ch, double>)> keys;

  /// Hand shapes over time: (from t, left, right).
  final List<(double, Hand?, Hand?)> hands;
}

/// Pose sampled each frame for the painter.
class PuppetPose {
  final v = <Ch, double>{for (final c in Ch.values) c: 0};
  double breath = 0; // 0..1 inhale
  double lidL = 0, lidR = 0; // 0 open .. 1 closed (blinks)
  Hand handL = Hand.relaxed, handR = Hand.relaxed;
  double operator [](Ch c) => v[c]!;
}

/// Character-specific behaviour: rest pose, emotion targets, gesture set.
abstract class PuppetSpec {
  Map<Ch, double> rest();
  Map<Ch, double> emotion(RigEmotion e);
  Gesture? gesture(String trigger, int variant);
  Gesture idleGesture(int variant);
  Gesture? speakingGesture(int n) => null;

  /// Sustained body pose while a boolean state is on.
  Map<Ch, double> listeningPose() => const {
    Ch.torsoLean: 0.06,
    Ch.headNod: 0.15,
  };
  Map<Ch, double> thinkingPose() => const {};
  (Hand?, Hand?) thinkingHands() => (null, null);
}

/// Simulates the character from controller inputs. Call [tick] per frame.
class PuppetMotor extends ChangeNotifier {
  PuppetMotor(this.spec, this.rig, {int? seed}) : _rng = math.Random(seed) {
    for (final e in spec.rest().entries) {
      _springs[e.key]!.x = e.value;
    }
    rig.addListener(_onRig);
    _nextBlink = 1 + _rng.nextDouble() * 2;
    _nextIdle = 5 + _rng.nextDouble() * 4;
  }

  final PuppetSpec spec;
  final CharacterRigController rig;
  final math.Random _rng;
  final pose = PuppetPose();
  final _springs = {for (final c in Ch.values) c: _Spring()};

  bool reducedMotion = false;
  double _t = 0;
  double _nextBlink = 0, _blinkT = -1, _secondBlink = -1;
  bool _pendingDouble = false;
  double _nextIdle = 0;
  int _idleCount = 0;
  Gesture? _g;
  double _gT = 0;
  double _speechT = 0;
  int _speechGestures = 0;
  double _nextSpeechGesture = 1.5;
  double _gazeHoldUntil = 0;
  double _idleGazeX = 0, _idleGazeY = 0;
  double _nodPhase = -1;

  bool get busy => _g != null;

  void _onRig() {
    for (final t in rig.drainTriggers()) {
      final g = spec.gesture(t, rig.idleVariant);
      if (t == RigContract.tapReaction) _gazeHoldUntil = _t + 1.6;
      if (t == RigContract.nod) _nodPhase = 0;
      if (g != null && !(reducedMotion && _isBodyGesture(g))) _play(g);
    }
  }

  bool _isBodyGesture(Gesture g) => g.keys.any(
    (k) => k.$2.keys.any(
      (c) => c.name.startsWith('arm') || c == Ch.kneeBend || c == Ch.torsoLean,
    ),
  );

  void _play(Gesture g) {
    _g = g;
    _gT = 0;
  }

  void tick(double dt) {
    dt = dt.clamp(0, 1 / 20);
    _t += dt;
    final targets = <Ch, double>{
      for (final c in Ch.values) c: 0,
      ...spec.rest(),
    };
    void add(Map<Ch, double> m, [double w = 1]) {
      for (final e in m.entries) {
        targets[e.key] = (targets[e.key] ?? 0) * (1 - w) + e.value * w;
      }
    }

    // 1. Expression layer.
    add(spec.emotion(rig.emotion));
    if (rig.happy) {
      targets[Ch.mouthSmile] = math.max(targets[Ch.mouthSmile]!, 0.7);
    }

    // 2. Sustained states.
    Hand? hl, hr;
    if (rig.listening) {
      add(spec.listeningPose());
    }
    if (rig.thinking) {
      add(spec.thinkingPose());
      (hl, hr) = spec.thinkingHands();
    }

    // 3. Gaze: explicit (tap / listening) or idle wandering.
    final explicit = _t < _gazeHoldUntil || rig.listening;
    var gx = explicit ? rig.gazeX : _idleGazeX;
    var gy = explicit ? rig.gazeY : _idleGazeY;
    if (rig.thinking) {
      gx = -0.6;
      gy = -0.7;
    }
    targets[Ch.pupilX] = gx;
    targets[Ch.pupilY] = gy;
    targets[Ch.headTurn] =
        (targets[Ch.headTurn] ?? 0) + gx * 0.45; // head follows eyes
    targets[Ch.headNod] = (targets[Ch.headNod] ?? 0) + gy * 0.25;

    // 4. Speech layer (only while real audio is playing).
    if (rig.speaking) {
      _speechT += dt;
      final amp = rig.voiceAmplitude;
      final syllables =
          0.5 +
          0.5 *
              math.sin(_speechT * 2 * math.pi * 4.3) *
              math.sin(_speechT * 2 * math.pi * 1.7 + 1.1);
      targets[Ch.mouthOpen] = (amp ?? (0.12 + 0.55 * syllables.abs())).clamp(
        0,
        1,
      );
      targets[Ch.headRot] =
          targets[Ch.headRot]! + 0.035 * math.sin(_speechT * 2 * math.pi * 0.9);
      targets[Ch.browL] = targets[Ch.browL]! + 0.25 * syllables;
      targets[Ch.browR] = targets[Ch.browR]! + 0.2 * syllables;
      if (!reducedMotion && _g == null && _speechT > _nextSpeechGesture) {
        final g = spec.speakingGesture(_speechGestures++);
        if (g != null) _play(g);
        _nextSpeechGesture = _speechT + 3 + _rng.nextDouble() * 2.5;
      }
    } else {
      _speechT = 0;
      _nextSpeechGesture = 1.2;
    }

    // 5. Listening nods (Professor) — occasional, not a loop.
    if (rig.listening &&
        !reducedMotion &&
        _nodPhase < 0 &&
        _rng.nextDouble() < dt * 0.35) {
      _nodPhase = 0;
    }
    if (_nodPhase >= 0) {
      _nodPhase += dt / 0.7;
      targets[Ch.headNod] =
          targets[Ch.headNod]! +
          0.35 * math.sin(math.pi * _nodPhase.clamp(0, 1));
      if (_nodPhase >= 1) _nodPhase = -1;
    }

    // 6. Gesture layer (blended in/out, never a cut).
    if (_g != null) {
      final g = _g!;
      _gT += dt / g.duration;
      final p = _gT.clamp(0.0, 1.0);
      final w = math
          .min(1.0, math.min(p / 0.12, (1 - p) / 0.15))
          .clamp(0.0, 1.0);
      final sample = _sample(g, p);
      for (final e in sample.entries) {
        final base = targets[e.key] ?? 0;
        targets[e.key] = base + (e.value - base) * _easeInOut(w);
      }
      for (final (from, l, r) in g.hands) {
        if (p >= from) {
          hl = l ?? hl;
          hr = r ?? hr;
        }
      }
      if (_gT >= 1) _g = null;
    }

    // 7. Idle life: variants on an irregular schedule.
    final idle = !rig.speaking && !rig.listening && !rig.thinking && _g == null;
    if (idle && !reducedMotion && _t > _nextIdle) {
      final variant = (_idleCount++ + rig.idleVariant) % 3;
      _play(spec.idleGesture(variant));
      _nextIdle = _t + 7 + _rng.nextDouble() * 9;
      if (variant == 1) {
        _idleGazeX = _rng.nextBool() ? -0.8 : 0.8;
        _idleGazeY = -0.2;
      }
    }
    if (idle && _rng.nextDouble() < dt * 0.25) {
      // Small eye saccades / return to the learner.
      _idleGazeX = _rng.nextDouble() < 0.5
          ? 0
          : (_rng.nextDouble() - 0.5) * 0.9;
      _idleGazeY = (_rng.nextDouble() - 0.5) * 0.4;
    }

    // Breathing: torso/shoulder deformation, never whole-body travel.
    final rate = rig.emotion == RigEmotion.sleepy ? 0.18 : 0.27;
    pose.breath = reducedMotion
        ? 0.3
        : 0.5 + 0.5 * math.sin(_t * 2 * math.pi * rate);
    if (!reducedMotion) {
      targets[Ch.shoulderL] = targets[Ch.shoulderL]! + 0.25 * pose.breath;
      targets[Ch.shoulderR] = targets[Ch.shoulderR]! + 0.25 * pose.breath;
      targets[Ch.hipShift] = targets[Ch.hipShift]! + 1.2 * math.sin(_t * 0.37);
    }

    // Springs (reduced motion: snap, no travel).
    for (final c in Ch.values) {
      final s = _springs[c]!;
      final target = targets[c] ?? 0;
      if (reducedMotion) {
        s
          ..x = target
          ..v = 0;
      } else {
        s.step(target, _stiff[c]!, dt);
      }
      pose.v[c] = s.x;
    }
    // Hair follows the head with lag (secondary motion).
    pose.v[Ch.hair] = reducedMotion
        ? 0
        : (pose[Ch.headRot] - _springs[Ch.hair]!.x) * 0.9;
    _springs[Ch.hair]!.step(pose[Ch.headRot], _stiff[Ch.hair]!, dt);

    pose.handL = hl ?? Hand.relaxed;
    pose.handR = hr ?? Hand.relaxed;
    _blink(dt);
    notifyListeners();
  }

  void _blink(double dt) {
    final sleepy = rig.emotion == RigEmotion.sleepy;
    if (sleepy) {
      pose.lidL = pose.lidR = 0.92;
      return;
    }
    // _blinkT: -1 = not blinking; >= 0 = time into the current blink.
    // _secondBlink: > 0 = pause remaining before a double-blink's second.
    if (_blinkT < 0) {
      if (_secondBlink > 0) {
        _secondBlink -= dt;
        if (_secondBlink <= 0) {
          _secondBlink = -1;
          _blinkT = 0;
        }
      } else if (_t > _nextBlink) {
        _blinkT = 0;
        _nextBlink = _t + 2.2 + _rng.nextDouble() * 4.3; // irregular 2.2–6.5 s
        if (_rng.nextDouble() < 0.18) _pendingDouble = true;
      }
    }
    var lid = 0.0;
    if (_blinkT >= 0) {
      _blinkT += dt;
      lid = _blinkCurve(_blinkT);
      if (_blinkT > 0.16) {
        _blinkT = -1;
        if (_pendingDouble) {
          _pendingDouble = false;
          _secondBlink = 0.12;
        }
      }
    }
    // Asymmetric by a hair: the right lid trails slightly.
    pose.lidL = lid;
    pose.lidR = lid * 0.96;
  }

  static double _blinkCurve(double t) =>
      t < 0.06 ? t / 0.06 : (t < 0.16 ? 1 - (t - 0.06) / 0.10 : 0);

  static Map<Ch, double> _sample(Gesture g, double p) {
    final keys = g.keys;
    final out = <Ch, double>{};
    final chans = {for (final k in keys) ...k.$2.keys};
    for (final c in chans) {
      (double, double)? a, b;
      for (final k in keys) {
        final v = k.$2[c];
        if (v == null) continue;
        if (k.$1 <= p) a = (k.$1, v);
        if (k.$1 >= p && b == null) b = (k.$1, v);
      }
      a ??= b;
      b ??= a;
      if (a == null || b == null) continue;
      final span = b.$1 - a.$1;
      final f = span <= 0 ? 0.0 : ((p - a.$1) / span).clamp(0.0, 1.0);
      out[c] = a.$2 + (b.$2 - a.$2) * _easeInOut(f);
    }
    return out;
  }

  @override
  void dispose() {
    rig.removeListener(_onRig);
    super.dispose();
  }
}

double _easeInOut(double t) =>
    t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
