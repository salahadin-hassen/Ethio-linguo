import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';

/// Rounded, animated progress bar with a glossy highlight.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.teal,
    this.track = AppColors.outline,
    this.height = 14,
    this.semanticLabel,
    this.from,
  });

  final double value;
  final Color color;
  final Color track;
  final double height;
  final String? semanticLabel;

  /// Optional starting fill for an animated reveal on first build.
  final double? from;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: track)),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: from?.clamp(0.0, 1.0), end: v),
                duration: Motion.of(
                  context,
                  from == null ? Motion.slow : Motion.celebrate,
                ),
                curve: Motion.emphasized,
                builder: (_, f, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: f,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(height),
                    ),
                    child: Align(
                      alignment: const Alignment(0, -0.45),
                      child: f <= 0.04
                          ? null
                          : Container(
                              height: height * 0.26,
                              margin: EdgeInsets.symmetric(
                                horizontal: height * 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(height),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular progress ring (levels, quests, units).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.child,
    this.size = 56,
    this.stroke = 6,
    this.color = AppColors.teal,
    this.track = AppColors.outline,
  });

  final double value;
  final Widget child;
  final double size;
  final double stroke;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: Motion.of(context, Motion.slow),
        curve: Motion.emphasized,
        builder: (_, v, c) => CustomPaint(
          painter: _RingPainter(v, stroke, color, track),
          child: Center(child: c),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.color, this.track);

  final double v;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.2832, false, p..color = track);
    if (v > 0) {
      canvas.drawArc(rect, -1.5708, 6.2832 * v, false, p..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color;
}
