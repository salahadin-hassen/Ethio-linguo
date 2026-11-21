import 'package:flutter/widgets.dart';

/// Motion tokens. All animated components read [Motion.of] so that the
/// platform "reduce motion" / "remove animations" setting is respected.
abstract final class Motion {
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const celebrate = Duration(milliseconds: 1600);

  static const emphasized = Curves.easeOutCubic;
  static const bouncy = Curves.easeOutBack;

  /// True when the user asked the OS to reduce or disable animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [d], or [Duration.zero] when reduced motion is requested.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
