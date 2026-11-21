import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';

/// Lightweight one-shot confetti burst (~48 particles, single painter, no
/// per-particle widgets) so it stays cheap on low-end Android. Skipped
/// entirely under reduced motion.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.particles = 48});

  final int particles;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.celebrate,
  );
  late final List<_Particle> _ps;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(11);
    const colors = [
      AppColors.coral,
      AppColors.teal,
      AppColors.gold,
      AppColors.periwinkle,
    ];
    _ps = List.generate(widget.particles, (i) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.1;
      final speed = 0.55 + rnd.nextDouble() * 0.6;
      return _Particle(
        dx: math.cos(angle) * speed,
        dy: math.sin(angle) * speed,
        spin: (rnd.nextDouble() - 0.5) * 12,
        color: colors[i % colors.length],
        size: 6 + rnd.nextDouble() * 6,
        circle: i % 5 == 0,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _ConfettiPainter(_ps, _c.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.dx,
    required this.dy,
    required this.spin,
    required this.color,
    required this.size,
    required this.circle,
  });
  final double dx, dy, spin, size;
  final Color color;
  final bool circle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.ps, this.t);
  final List<_Particle> ps;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final origin = Offset(size.width / 2, size.height * 0.38);
    final scale = size.shortestSide * 0.9;
    final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
    for (final p in ps) {
      final pos =
          origin + Offset(p.dx * t * scale, (p.dy * t + 0.9 * t * t) * scale);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2.4, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 0.6,
              height: p.size,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
