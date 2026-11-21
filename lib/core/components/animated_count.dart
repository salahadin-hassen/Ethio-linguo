import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// Number that counts up/down to [value] when it changes.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.duration,
    this.from,
  });

  final int value;
  final TextStyle? style;
  final String prefix;
  final Duration? duration;

  /// Optional starting value for a count-up on first build.
  final int? from;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from?.toDouble(), end: value.toDouble()),
      duration: Motion.of(context, duration ?? Motion.slow),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('$prefix${v.round()}', style: style),
    );
  }
}
