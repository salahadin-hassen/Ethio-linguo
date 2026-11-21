import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Motion tokens: the ONE motion language of the app (docs/MOTION.md).
/// All animated components read [Motion.of] so the OS "reduce motion" /
/// "remove animations" setting is respected everywhere.
abstract final class Motion {
  // Durations, by purpose.
  static const press = Duration(milliseconds: 120); // button / tile press
  static const fast = Duration(milliseconds: 140); // legacy alias ~ press
  static const feedback = Duration(milliseconds: 200); // small state feedback
  static const medium = Duration(milliseconds: 260); // card / screen
  static const card = Duration(milliseconds: 280);
  static const reaction = Duration(milliseconds: 380); // character reaction
  static const screen = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 420); // progress fills
  static const achievement = Duration(milliseconds: 900);
  static const celebrate = Duration(milliseconds: 1600); // lesson complete

  // Curves, by purpose.
  static const emphasized = Curves.easeOutCubic; // entrances, state changes
  static const exit = Curves.easeInCubic; // things leaving
  static const bouncy = Curves.easeOutBack; // gentle overshoot (selection)
  static const spring = _Spring(); // character reactions, rewards

  /// True when the user asked the OS to reduce or disable animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [d], or [Duration.zero] when reduced motion is requested.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Under-damped spring: quick rise, one small overshoot (~8%), settles.
class _Spring extends Curve {
  const _Spring();
  @override
  double transformInternal(double t) =>
      1 - math.exp(-6.5 * t) * math.cos(9.5 * t);
}
