import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import 'mascot_mood.dart';
import 'mascot_painter.dart';

export 'mascot_mood.dart';

/// The mascot widget. Idle motion (breathing, waving, blinking) loops while
/// [animate] is true and the OS has not requested reduced motion. Changing
/// [mood] cross-fades with a small pop so expression changes read clearly.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    required this.mood,
    this.size = 160,
    this.animate = true,
    this.semanticLabel,
  });

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

  /// A quick blink near the end of each loop.
  double _blinkAt(double t) {
    const start = 0.86, end = 0.94;
    if (t < start || t > end) return 0;
    return math.sin((t - start) / (end - start) * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return Semantics(
      image: true,
      label: widget.semanticLabel ?? 'Mascot, ${widget.mood.name}',
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
          key: ValueKey(widget.mood),
          child: SizedBox.square(
            dimension: widget.size,
            child: reduced || !widget.animate
                ? CustomPaint(painter: MascotPainter(mood: widget.mood))
                : AnimatedBuilder(
                    animation: _loop,
                    builder: (_, _) => CustomPaint(
                      painter: MascotPainter(
                        mood: widget.mood,
                        t: _loop.value,
                        blink: _blinkAt(_loop.value),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
