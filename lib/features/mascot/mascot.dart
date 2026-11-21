import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion/motion.dart';
import 'characters.dart';
import 'mascot_mood.dart';

export 'characters.dart';
export 'mascot_mood.dart';

/// Back-compatible entry point: mood -> cast member + state. Screens that
/// care about a specific person/state use [CharacterAvatar] directly.
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    required this.mood,
    this.size = 160,
    this.animate = true,
    this.semanticLabel,
    this.character,
    this.state,
    this.onTap,
    this.reactOnMount = false,
  });

  final bool reactOnMount;
  final MascotMood mood;
  final double size;
  final bool animate;
  final String? semanticLabel;
  final CastMember? character;
  final CharacterState? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (who, s) = castForMood(mood);
    return CharacterAvatar(
      character: character ?? who,
      state: state ?? s,
      size: size,
      animate: animate,
      semanticLabel: semanticLabel,
      onTap: onTap,
      reactOnMount: reactOnMount,
    );
  }
}

enum _Reaction { none, hop, doubleHop, tilt, wave, pop, glance, lean }

_Reaction _reactionFor(CharacterState s) => switch (s) {
  CharacterState.happy || CharacterState.approving => _Reaction.hop,
  CharacterState.excited || CharacterState.celebrating => _Reaction.doubleHop,
  CharacterState.confused ||
  CharacterState.correcting ||
  CharacterState.surprised => _Reaction.tilt,
  CharacterState.greeting || CharacterState.waving => _Reaction.wave,
  CharacterState.encouraging ||
  CharacterState.speaking ||
  CharacterState.explaining => _Reaction.pop,
  CharacterState.listening || CharacterState.curious => _Reaction.lean,
  CharacterState.thinking || CharacterState.transcribing => _Reaction.glance,
  CharacterState.idle || CharacterState.sleeping => _Reaction.none,
};

/// A living cast member.
///
/// - The pose follows [state]; every state change plays a short reaction
///   (hop, tilt, wave, lean…) so the change is *felt*, not just swapped.
/// - Idle life: slow breathing and an occasional glance — restrained.
/// - [speaking] must reflect REAL audio playback; only then does the
///   character move as if talking (no fake lip-sync).
/// - Thinking shows animated thought dots instead of a spinner.
/// - Tapping plays a small happy reaction (+ haptic) and calls [onTap].
/// - Reduced motion: pose changes only, no movement, no timers.
///
/// Blinking needs eyelid artwork (a rigged/Rive asset); it is NOT faked.
class CharacterAvatar extends StatefulWidget {
  const CharacterAvatar({
    super.key,
    required this.character,
    required this.state,
    this.size = 160,
    this.speaking = false,
    this.animate = true,
    this.onTap,
    this.semanticLabel,
    this.reactOnMount = false,
  });

  /// Play the state's reaction when first shown (e.g. a feedback panel that
  /// appears *because* of an event).
  final bool reactOnMount;
  final CastMember character;
  final CharacterState state;
  final double size;
  final bool speaking;
  final bool animate;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<CharacterAvatar> createState() => _CharacterAvatarState();
}

class _CharacterAvatarState extends State<CharacterAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _react = AnimationController(
    vsync: this,
    duration: Motion.reaction,
  );
  _Reaction _kind = _Reaction.none;
  Timer? _glance;
  final _rng = math.Random();
  bool _live = false;

  bool get _wantsLoop =>
      widget.speaking ||
      widget.state == CharacterState.thinking ||
      widget.state == CharacterState.transcribing ||
      widget.state == CharacterState.sleeping ||
      _idleLike;

  bool get _idleLike => switch (widget.state) {
    CharacterState.idle ||
    CharacterState.greeting ||
    CharacterState.waving ||
    CharacterState.encouraging ||
    CharacterState.happy ||
    CharacterState.curious ||
    CharacterState.listening => true,
    _ => false,
  };

  bool _mounted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
    if (!_mounted) {
      _mounted = true;
      if (widget.reactOnMount) _play(_reactionFor(widget.state));
    }
  }

  @override
  void didUpdateWidget(CharacterAvatar old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state || old.character != widget.character) {
      _play(_reactionFor(widget.state));
    }
    _sync();
  }

  void _sync() {
    final live =
        widget.animate &&
        !Motion.reduced(context) &&
        TickerMode.valuesOf(context).enabled;
    _live = live;
    if (live && _wantsLoop) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
    }
    _glance?.cancel();
    _glance = null;
    if (live && _idleLike) _scheduleGlance();
  }

  void _scheduleGlance() {
    _glance = Timer(Duration(milliseconds: 7000 + _rng.nextInt(6000)), () {
      if (!mounted || !_live) return;
      _play(_Reaction.glance);
      _scheduleGlance();
    });
  }

  void _play(_Reaction r) {
    if (!_live || r == _Reaction.none) return;
    _kind = r;
    _react.duration = switch (r) {
      _Reaction.doubleHop => Motion.achievement,
      _Reaction.wave => const Duration(milliseconds: 700),
      _Reaction.glance => const Duration(milliseconds: 900),
      _ => Motion.reaction,
    };
    _react.forward(from: 0);
  }

  void _tap() {
    HapticFeedback.selectionClick();
    _play(_Reaction.hop);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _glance?.cancel();
    _loop.dispose();
    _react.dispose();
    super.dispose();
  }

  Matrix4 _transform() {
    final s = widget.size;
    final t = _loop.value;
    final r = _react.value;
    var dy = 0.0, rot = 0.0, scale = 1.0, sy = 1.0;

    // Ambient life.
    if (widget.speaking) {
      // Talking cadence, only while audio is really playing.
      dy -= s * 0.018 * math.sin(2 * math.pi * t * 8).abs();
      rot += 0.012 * math.sin(2 * math.pi * t * 4);
    } else if (widget.state == CharacterState.sleeping) {
      sy += 0.02 * math.sin(2 * math.pi * t * 0.7);
    } else {
      sy += 0.012 * math.sin(2 * math.pi * t); // breathing
    }
    if (widget.state == CharacterState.listening) {
      rot -= 0.05; // leans toward the learner / mic
      scale *= 1.03;
    }

    // One-shot reaction.
    final damp = 1 - r;
    switch (_kind) {
      case _Reaction.hop:
        dy -= s * 0.11 * math.sin(math.pi * r);
        sy += r > 0.85 ? -0.05 * math.sin((r - 0.85) / 0.15 * math.pi) : 0;
      case _Reaction.doubleHop:
        dy -= s * 0.1 * math.sin(2 * math.pi * r).abs();
        scale *= 1 + 0.04 * math.sin(math.pi * r);
      case _Reaction.tilt:
        rot += 0.09 * math.sin(2 * math.pi * r) * damp;
      case _Reaction.wave:
        rot += 0.06 * math.sin(4 * math.pi * r) * damp;
      case _Reaction.pop:
        scale *= 1 + 0.07 * math.sin(math.pi * r);
      case _Reaction.glance:
        rot += 0.035 * math.sin(2 * math.pi * r);
      case _Reaction.lean:
        scale *= 1 + 0.04 * math.sin(math.pi * r);
      case _Reaction.none:
        break;
    }
    return Matrix4.identity()
      ..translateByDouble(0, dy, 0, 1)
      ..rotateZ(rot)
      ..scaleByDouble(scale, scale * sy, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final pose = poseForState(widget.character, widget.state);
    final reduced = !_live;
    final art = AnimatedSwitcher(
      duration: Motion.of(context, Motion.reaction),
      switchInCurve: Motion.bouncy,
      switchOutCurve: Motion.exit,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(anim),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: Image.asset(
        characterAsset(widget.character, pose),
        key: ValueKey((widget.character, pose)),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        gaplessPlayback: true,
      ),
    );
    final thinking =
        widget.state == CharacterState.thinking ||
        widget.state == CharacterState.transcribing;
    final body = SizedBox.square(
      dimension: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: reduced
                ? art
                : AnimatedBuilder(
                    animation: Listenable.merge([_loop, _react]),
                    child: art,
                    builder: (_, child) => Transform(
                      alignment: Alignment.bottomCenter,
                      transform: _transform(),
                      child: child,
                    ),
                  ),
          ),
          if (thinking)
            Positioned(
              right: widget.size * 0.02,
              top: 0,
              child: _ThoughtDots(
                loop: _loop,
                size: widget.size * 0.07,
                live: !reduced,
              ),
            ),
          if (widget.state == CharacterState.sleeping)
            Positioned(
              right: widget.size * 0.08,
              top: 0,
              child: Text(
                'z',
                style: TextStyle(
                  fontSize: widget.size * 0.14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7183F5),
                ),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      image: true,
      button: widget.onTap != null,
      label:
          widget.semanticLabel ??
          '${widget.character.displayName}, ${widget.state.name}',
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap == null ? null : _tap,
          child: body,
        ),
      ),
    );
  }
}

/// Three dots that rise in turn: "I'm thinking about your answer".
class _ThoughtDots extends StatelessWidget {
  const _ThoughtDots({
    required this.loop,
    required this.size,
    required this.live,
  });
  final Animation<double> loop;
  final double size;
  final bool live;

  @override
  Widget build(BuildContext context) {
    Widget dots(double t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(left: size * 0.4),
            child: Opacity(
              opacity: live
                  ? 0.35 +
                        0.65 *
                            math.sin(math.pi * ((t * 3 - i * 0.33) % 1)).abs()
                  : 0.8,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: Color(0xFF7183F5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
    return live
        ? AnimatedBuilder(animation: loop, builder: (_, _) => dots(loop.value))
        : dots(0);
  }
}
