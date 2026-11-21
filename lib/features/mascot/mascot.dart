import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion/motion.dart';
import 'characters.dart';
import 'mascot_mood.dart';
import 'rig/character_rig_controller.dart';
import 'rig/rig_contract.dart';
import 'rig/rive_character.dart';

export 'characters.dart';
export 'rig/character_rig_controller.dart';
export 'rig/rig_contract.dart';
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

/// A cast member.
///
/// When the designer's rigged Rive file for this character is bundled
/// (RigContract.specs), the character is rendered by Rive and ALL motion is
/// authored there: breathing, blinking, gaze, gestures, mouth. The app only
/// sends meaningful inputs through [CharacterRigController] (state, speaking
/// from real audio playback, taps, triggers).
///
/// Without a rig, the app shows the static pose for the state (cross-fade on
/// change) and does NOT fake character animation — no whole-image bouncing
/// (rejected; see docs/CHARACTER_RIG_SPEC.md).
class CharacterAvatar extends StatefulWidget {
  const CharacterAvatar({
    super.key,
    required this.character,
    required this.state,
    this.size = 160,
    this.speaking = false,
    this.voiceAmplitude,
    this.animate = true,
    this.onTap,
    this.semanticLabel,
    this.reactOnMount = false,
    this.rig,
  });

  final CastMember character;
  final CharacterState state;
  final double size;

  /// Must reflect REAL audio playback (drives the rig's speech layer).
  final bool speaking;

  /// Real playback level when a source provides one; otherwise null.
  final double? voiceAmplitude;
  final bool animate;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Fire the state's event trigger on first show (e.g. a feedback panel
  /// that appears because of an answer).
  final bool reactOnMount;

  /// Optional external controller (e.g. a screen that fires celebrate()).
  final CharacterRigController? rig;

  @override
  State<CharacterAvatar> createState() => _CharacterAvatarState();
}

class _CharacterAvatarState extends State<CharacterAvatar> {
  late CharacterRigController _rig = widget.rig ?? CharacterRigController();
  late final Future<bool> _hasRig = RigAssets.available(widget.character);
  int _taps = 0;

  @override
  void initState() {
    super.initState();
    _rig.applyState(
      widget.state,
      previous: widget.reactOnMount ? null : widget.state,
    );
    _rig.setSpeaking(widget.speaking, amplitude: widget.voiceAmplitude);
  }

  @override
  void didUpdateWidget(CharacterAvatar old) {
    super.didUpdateWidget(old);
    if (widget.rig != null && widget.rig != _rig) _rig = widget.rig!;
    if (old.state != widget.state) {
      _rig.applyState(widget.state, previous: old.state);
    }
    if (old.speaking != widget.speaking ||
        old.voiceAmplitude != widget.voiceAmplitude) {
      _rig.setSpeaking(widget.speaking, amplitude: widget.voiceAmplitude);
    }
  }

  @override
  void dispose() {
    if (widget.rig == null) _rig.dispose();
    super.dispose();
  }

  void _tap(TapUpDetails d) {
    HapticFeedback.selectionClick();
    final half = widget.size / 2;
    _rig
      ..setIdleVariant(_taps++)
      ..reactToTap(
        x: (d.localPosition.dx - half) / half,
        y: (d.localPosition.dy - half) / half,
      );
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context) || !widget.animate;
    final fallback = _StaticPose(
      character: widget.character,
      state: widget.state,
      size: widget.size,
    );
    final spec = RigContract.specs[widget.character];
    final view = spec == null
        ? fallback
        : FutureBuilder<bool>(
            future: _hasRig,
            builder: (context, snap) => snap.data == true
                ? RiveCharacter(
                    spec: spec,
                    controller: _rig,
                    reducedMotion: reduced,
                    fallback: fallback,
                  )
                : fallback,
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
          onTapUp: widget.onTap == null ? null : _tap,
          child: SizedBox.square(dimension: widget.size, child: view),
        ),
      ),
    );
  }
}

/// Fallback when no rig is bundled: the authored pose for the state, with a
/// quick cross-fade between poses. Deliberately no motion.
class _StaticPose extends StatelessWidget {
  const _StaticPose({
    required this.character,
    required this.state,
    required this.size,
  });

  final CastMember character;
  final CharacterState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pose = poseForState(character, state);
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.feedback),
      child: Image.asset(
        characterAsset(character, pose),
        key: ValueKey((character, pose)),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        gaplessPlayback: true,
      ),
    );
  }
}
