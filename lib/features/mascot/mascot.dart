import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import 'mascot_mood.dart';
import 'characters.dart';

export 'characters.dart';
export 'mascot_mood.dart';

/// A cast character (human cast, see characters.dart). [character] pins a
/// specific person (e.g. the Professor in Speak); otherwise the mood picks
/// who appears. A gentle idle bob loops while [animate] is true and the OS
/// has not requested reduced motion. Changes cross-fade with a small pop.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    required this.mood,
    this.size = 160,
    this.animate = true,
    this.semanticLabel,
    this.character,
  });

  final CastMember? character;
  final MascotMood mood;
  final double size;
  final bool animate;
  final String? semanticLabel;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    _syncLoop();
  }

  void _syncLoop() {
    final shouldRun =
        widget.animate &&
        !Motion.reduced(context) &&
        TickerMode.valuesOf(context).enabled;
    if (shouldRun && !_running) {
      _loop.repeat();
    } else if (!shouldRun && _running) {
      _loop.stop();
    }
    _running = shouldRun;
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final (member, pose) = widget.character == null
        ? castForMood(widget.mood)
        : (widget.character!, poseFor(widget.character!, widget.mood));
    final image = Image.asset(
      characterAsset(member, pose),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      gaplessPlayback: true,
    );
    return Semantics(
      image: true,
      label:
          widget.semanticLabel ?? '${member.displayName}, ${widget.mood.name}',
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.medium),
        switchInCurve: Motion.bouncy,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.88, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: RepaintBoundary(
          key: ValueKey((member, pose)),
          child: SizedBox.square(
            dimension: widget.size,
            child: reduced || !widget.animate
                ? image
                : AnimatedBuilder(
                    animation: _loop,
                    child: image,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(
                        0,
                        -math.sin(_loop.value * 2 * math.pi).abs() *
                            widget.size *
                            0.025,
                      ),
                      child: child,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
