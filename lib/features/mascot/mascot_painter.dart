import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'mascot_mood.dart';

/// Vector painter for the working-title mascot ("Gela", placeholder name):
/// a gelada-inspired companion with a golden mane, a coral heart chest patch
/// and a teal scarf trimmed with a tibeb-style woven band.
///
/// Drawn on a 200×200 design grid and scaled to the widget size, so it stays
/// crisp from 40px avatars to full-screen hero art. [t] is a 0..1 looping
/// phase used for idle motion (breathing, waving, blinking).
class MascotPainter extends CustomPainter {
  MascotPainter({required this.mood, this.t = 0, this.blink = 0});

  final MascotMood mood;
  final double t;

  /// 0 = eyes open, 1 = fully closed (blink).
  final double blink;

  static const _maneColor = Color(0xFFE9A23B);
  static const _maneDeep = Color(0xFFD08A2A);
  static const _fur = AppColors.gold;
  static const _face = Color(0xFFFFEBD2);
  static const _muzzle = Color(0xFFF7D3AA);
  static const _ink = AppColors.indigo;
  static const _hand = Color(0xFFD08A2A);

  @override
  void paint(Canvas canvas, Size size) {
    final spec = MoodSpec.of(mood);
    final s = math.min(size.width, size.height) / 200;
    canvas.save();
    canvas.translate((size.width - 200 * s) / 2, (size.height - 200 * s) / 2);
    canvas.scale(s);

    final phase = t * 2 * math.pi;
    final breathe = math.sin(phase) * 1.6;
    final bounce = spec.arms == ArmPose.bothUp
        ? -math.sin(phase * 2).abs() * 5
        : 0.0;

    _shadow(canvas, bounce);
    canvas.save();
    canvas.translate(0, bounce);

    _body(canvas, breathe);
    _drawMane(canvas, breathe);
    _scarf(canvas, breathe);
    _head(canvas, spec, breathe);
    _arms(canvas, spec.arms, phase);
    canvas.restore();

    _prop(canvas, spec.prop, phase);
    canvas.restore();
  }

  // ---------------------------------------------------------------- parts

  void _shadow(Canvas c, double bounce) {
    final w = 104 + bounce * 2;
    c.drawOval(
      Rect.fromCenter(center: const Offset(100, 190), width: w, height: 12),
      Paint()..color = _ink.withValues(alpha: 0.10),
    );
  }

  void _body(Canvas c, double breathe) {
    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(54, 120 - breathe * 0.4, 146, 188),
      topLeft: const Radius.circular(40),
      topRight: const Radius.circular(40),
      bottomLeft: const Radius.circular(30),
      bottomRight: const Radius.circular(30),
    );
    c.drawRRect(body, Paint()..color = _fur);
    // Soft side shading for volume.
    c.save();
    c.clipRRect(body);
    c.drawOval(
      Rect.fromLTRB(118, 118, 170, 196),
      Paint()..color = _maneDeep.withValues(alpha: 0.22),
    );
    c.restore();
    // Belly + heart patch (the gelada's signature chest mark).
    c.drawOval(
      Rect.fromCenter(center: const Offset(100, 163), width: 60, height: 44),
      Paint()..color = _face,
    );
    _heartPath(c, const Offset(100, 162), 13 + breathe * 0.4, AppColors.coral);
  }

  void _drawMane(Canvas c, double breathe) {
    final paint = Paint()..color = _maneColor;
    const center = Offset(100, 84);
    final r = 56.0 + breathe * 0.5;
    c.drawCircle(center, r - 4, paint);
    // Scalloped fluffy silhouette, fuller at the cheeks and shoulders.
    for (var i = 0; i < 14; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / 14);
      final lower = math.sin(a) > 0.2;
      final rr = lower ? 17.0 : 15.0;
      final dist = lower ? r - 6 : r - 8;
      c.drawCircle(
        center + Offset(math.cos(a) * dist, math.sin(a) * dist * 0.96),
        rr,
        paint,
      );
    }
    // Inner shadow ring for depth.
    c.drawCircle(
      center + const Offset(0, 6),
      44,
      Paint()..color = _maneDeep.withValues(alpha: 0.35),
    );
  }

  void _scarf(Canvas c, double breathe) {
    final y = 128.0 - breathe * 0.3;
    final band = RRect.fromRectAndRadius(
      Rect.fromLTRB(60, y, 140, y + 16),
      const Radius.circular(8),
    );
    // Tail hanging to the side.
    c.save();
    c.translate(130, y + 10);
    c.rotate(-0.22);
    final tail = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-7, 0, 15, 30),
      const Radius.circular(6),
    );
    c.drawRRect(tail, Paint()..color = AppColors.tealShade);
    _tibebStripe(c, const Rect.fromLTWH(-7, 22, 15, 5));
    c.restore();
    c.drawRRect(band, Paint()..color = AppColors.teal);
    _tibebStripe(c, Rect.fromLTRB(66, y + 6, 134, y + 10.5));
  }

  /// Small repeating woven motif inspired by tibeb borders: alternating
  /// diamonds in coral, gold and indigo.
  void _tibebStripe(Canvas c, Rect r) {
    final colors = [AppColors.coral, AppColors.gold, AppColors.indigo];
    final h = r.height;
    var i = 0;
    for (var x = r.left; x + h <= r.right + 0.1; x += h) {
      final cx = x + h / 2;
      final cy = r.center.dy;
      final p = Path()
        ..moveTo(cx, cy - h / 2)
        ..lineTo(cx + h / 2, cy)
        ..lineTo(cx, cy + h / 2)
        ..lineTo(cx - h / 2, cy)
        ..close();
      c.drawPath(p, Paint()..color = colors[i++ % 3]);
    }
  }

  void _head(Canvas c, MoodSpec spec, double breathe) {
    // Ears.
    for (final dx in [-1.0, 1.0]) {
      final ear = Offset(100 + dx * 42, 80);
      c.drawCircle(ear, 11, Paint()..color = _fur);
      c.drawCircle(
        ear,
        6,
        Paint()..color = AppColors.coral.withValues(alpha: 0.45),
      );
    }
    // Head fur.
    c.drawCircle(const Offset(100, 84), 40, Paint()..color = _fur);
    // Signature hair tuft — keeps the silhouette recognisable at small sizes.
    final tuft = Path()
      ..moveTo(90, 50)
      ..quadraticBezierTo(88, 30, 100, 24)
      ..quadraticBezierTo(97, 36, 104, 40)
      ..quadraticBezierTo(108, 28, 118, 30)
      ..quadraticBezierTo(110, 40, 112, 50)
      ..close();
    c.drawPath(tuft, Paint()..color = _fur);
    // Face mask — slightly heart-shaped, like a gelada's pale face.
    final face = Path()
      ..moveTo(100, 62)
      ..cubicTo(122, 52, 134, 72, 128, 92)
      ..cubicTo(124, 110, 112, 118, 100, 118)
      ..cubicTo(88, 118, 76, 110, 72, 92)
      ..cubicTo(66, 72, 78, 52, 100, 62)
      ..close();
    c.drawPath(face, Paint()..color = _face);

    if (spec.blush) {
      final blush = Paint()..color = AppColors.coral.withValues(alpha: 0.32);
      c.drawOval(
        Rect.fromCenter(center: const Offset(80, 99), width: 13, height: 8),
        blush,
      );
      c.drawOval(
        Rect.fromCenter(center: const Offset(120, 99), width: 13, height: 8),
        blush,
      );
    }

    _eyes(c, spec.eyes);
    _brows(c, spec.brows);

    // Muzzle.
    c.drawOval(
      Rect.fromCenter(center: const Offset(100, 104), width: 34, height: 22),
      Paint()..color = _muzzle,
    );
    final nose = Paint()..color = _ink;
    c.drawOval(
      Rect.fromCenter(center: const Offset(95.5, 99), width: 4, height: 3),
      nose,
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(104.5, 99), width: 4, height: 3),
      nose,
    );
    _mouth(c, spec.mouth);
  }

  void _eyes(Canvas c, EyeStyle style) {
    final ink = Paint()..color = _ink;
    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    const l = Offset(86, 84);
    const r = Offset(114, 84);

    switch (style) {
      case EyeStyle.happy:
        for (final e in [l, r]) {
          c.drawArc(
            Rect.fromCenter(
              center: e + const Offset(0, 3),
              width: 13,
              height: 12,
            ),
            math.pi * 1.1,
            math.pi * 0.8,
            false,
            stroke,
          );
        }
      case EyeStyle.closed:
        for (final e in [l, r]) {
          c.drawArc(
            Rect.fromCenter(
              center: e + const Offset(0, -1),
              width: 12,
              height: 9,
            ),
            math.pi * 0.15,
            math.pi * 0.7,
            false,
            stroke,
          );
        }
      case EyeStyle.open || EyeStyle.wide || EyeStyle.lookAside:
        final wide = style == EyeStyle.wide;
        final look = style == EyeStyle.lookAside
            ? const Offset(2.5, -2.5)
            : Offset.zero;
        final h = (wide ? 15.0 : 13.0) * (1 - blink * 0.9);
        final w = wide ? 12.0 : 10.5;
        for (final e in [l, r]) {
          c.drawOval(
            Rect.fromCenter(center: e + look, width: w, height: h),
            ink,
          );
          if (blink < 0.5) {
            c.drawCircle(
              e + look + const Offset(2, -3),
              wide ? 3 : 2.4,
              Paint()..color = Colors.white,
            );
            c.drawCircle(
              e + look + const Offset(-2, 2.5),
              1.1,
              Paint()..color = Colors.white.withValues(alpha: 0.8),
            );
          }
          if (wide) {
            // Star-glint for excitement.
            _sparkle(c, e + look + const Offset(-1.5, 2.5), 2.2, Colors.white);
          }
        }
    }
  }

  void _brows(Canvas c, BrowStyle style) {
    if (style == BrowStyle.none) return;
    final p = Paint()
      ..color = _maneDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    void brow(Offset a, Offset b) => c.drawLine(a, b, p);
    switch (style) {
      case BrowStyle.neutral:
        brow(const Offset(80, 71), const Offset(91, 71));
        brow(const Offset(109, 71), const Offset(120, 71));
      case BrowStyle.raised:
        c.drawArc(
          Rect.fromCenter(center: const Offset(86, 72), width: 13, height: 8),
          math.pi * 1.15,
          math.pi * 0.7,
          false,
          p,
        );
        c.drawArc(
          Rect.fromCenter(center: const Offset(114, 72), width: 13, height: 8),
          math.pi * 1.15,
          math.pi * 0.7,
          false,
          p,
        );
      case BrowStyle.worried:
        brow(const Offset(80, 73), const Offset(91, 69));
        brow(const Offset(109, 69), const Offset(120, 73));
      case BrowStyle.quizzical:
        brow(const Offset(80, 72), const Offset(91, 72));
        brow(const Offset(109, 68), const Offset(120, 65));
      case BrowStyle.none:
        break;
    }
  }

  void _mouth(Canvas c, MouthStyle style) {
    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    switch (style) {
      case MouthStyle.smile:
        c.drawArc(
          Rect.fromCenter(
            center: const Offset(100, 105),
            width: 14,
            height: 10,
          ),
          0.2,
          math.pi - 0.4,
          false,
          stroke,
        );
      case MouthStyle.soft:
        c.drawArc(
          Rect.fromCenter(center: const Offset(100, 106), width: 10, height: 7),
          0.25,
          math.pi - 0.5,
          false,
          stroke,
        );
      case MouthStyle.grin || MouthStyle.open:
        final big = style == MouthStyle.open;
        final rect = Rect.fromCenter(
          center: Offset(100, big ? 108 : 107),
          width: big ? 18 : 16,
          height: big ? 14 : 10,
        );
        final path = Path()
          ..moveTo(rect.left, rect.top)
          ..quadraticBezierTo(
            rect.center.dx,
            rect.top + 2,
            rect.right,
            rect.top,
          )
          ..quadraticBezierTo(
            rect.right,
            rect.bottom,
            rect.center.dx,
            rect.bottom,
          )
          ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.top)
          ..close();
        c.drawPath(path, Paint()..color = _ink);
        c.save();
        c.clipPath(path);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(100, rect.bottom),
            width: rect.width * 0.7,
            height: rect.height * 0.8,
          ),
          Paint()..color = AppColors.coral,
        );
        c.restore();
      case MouthStyle.small:
        c.drawOval(
          Rect.fromCenter(center: const Offset(103, 109), width: 6, height: 6),
          Paint()..color = _ink,
        );
      case MouthStyle.wavy:
        final p = Path()
          ..moveTo(92, 109)
          ..quadraticBezierTo(96, 105, 100, 109)
          ..quadraticBezierTo(104, 113, 108, 108);
        c.drawPath(p, stroke);
      case MouthStyle.sleepy:
        c.drawOval(
          Rect.fromCenter(center: const Offset(100, 109), width: 5, height: 4),
          Paint()..color = _ink,
        );
    }
  }

  void _arms(Canvas c, ArmPose pose, double phase) {
    // Each arm: shoulder pivot + angle (radians, 0 = pointing down).
    const ls = Offset(64, 140);
    const rs = Offset(136, 140);
    final wave = math.sin(phase * 2) * 0.35;
    final (double la, double ra) = switch (pose) {
      ArmPose.rest => (0.35, -0.35),
      ArmPose.hug => (-0.55, 0.55),
      ArmPose.wave => (0.35, -2.6 + wave),
      ArmPose.bothUp => (2.55 + wave * 0.4, -2.55 - wave * 0.4),
      ArmPose.chin => (0.35, 2.75),
      ArmPose.shrug => (2.05, -2.05),
      ArmPose.thumbUp => (0.35, -2.2),
    };
    final shortL = pose == ArmPose.hug || pose == ArmPose.shrug;
    _arm(c, ls, la, shortL);
    _arm(c, rs, ra, shortL || pose == ArmPose.chin);
    if (pose == ArmPose.thumbUp) {
      final hand = rs + Offset(-math.sin(ra) * 34, math.cos(ra) * 34);
      final thumb = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: hand + const Offset(0, -10),
          width: 7,
          height: 12,
        ),
        const Radius.circular(4),
      );
      c.drawRRect(thumb, Paint()..color = _hand);
    }
  }

  void _arm(Canvas c, Offset shoulder, double angle, bool short) {
    final len = short ? 26.0 : 34.0;
    final end =
        shoulder + Offset(-math.sin(angle) * len, math.cos(angle) * len);
    c.drawLine(
      shoulder,
      end,
      Paint()
        ..color = _fur
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.round,
    );
    // Subtle outline on the arm so it separates from the body.
    c.drawLine(
      shoulder,
      end,
      Paint()
        ..color = _maneDeep.withValues(alpha: 0.25)
        ..strokeWidth = 17
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.multiply,
    );
    c.drawCircle(end, 9.5, Paint()..color = _hand);
  }

  void _prop(Canvas c, MascotProp prop, double phase) {
    final float = math.sin(phase) * 3;
    switch (prop) {
      case MascotProp.none:
        break;
      case MascotProp.sparkles:
        _sparkle(c, Offset(34, 46 + float), 9, AppColors.gold);
        _sparkle(c, Offset(166, 38 - float), 11, AppColors.periwinkle);
        _sparkle(c, Offset(172, 92 + float), 6, AppColors.coral);
        _sparkle(c, Offset(26, 104 - float), 6, AppColors.teal);
      case MascotProp.confetti:
        final colors = [
          AppColors.coral,
          AppColors.teal,
          AppColors.periwinkle,
          AppColors.gold,
        ];
        final rnd = math.Random(3);
        for (var i = 0; i < 14; i++) {
          final x = 16 + rnd.nextDouble() * 168;
          final y = 10 + rnd.nextDouble() * 60 + math.sin(phase + i) * 4;
          c.save();
          c.translate(x, y);
          c.rotate(
            rnd.nextDouble() * math.pi + phase * (i.isEven ? 1 : -1) * 0.5,
          );
          c.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-3, -5, 6, 10),
              const Radius.circular(2),
            ),
            Paint()..color = colors[i % 4],
          );
          c.restore();
        }
      case MascotProp.question:
        final tp = TextPainter(
          text: const TextSpan(
            text: '?',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.periwinkle,
              fontFamily: 'Nunito',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(148, 22 + float));
      case MascotProp.thoughtDots:
        final p = Paint()..color = AppColors.periwinkle;
        c.drawCircle(Offset(140, 52 + float * 0.5), 4, p);
        c.drawCircle(Offset(152, 38 + float * 0.7), 6, p);
        c.drawCircle(Offset(168, 20 + float), 9, p);
      case MascotProp.zzz:
        for (var i = 0; i < 3; i++) {
          final tp = TextPainter(
            text: TextSpan(
              text: 'z',
              style: TextStyle(
                fontSize: 14.0 + i * 6,
                fontWeight: FontWeight.w900,
                color: AppColors.periwinkle.withValues(alpha: 0.6 + i * 0.2),
                fontFamily: 'Nunito',
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            c,
            Offset(138.0 + i * 12, 52.0 - i * 16 + float * (i + 1) * 0.4),
          );
        }
      case MascotProp.heart:
        _heartPath(c, Offset(160, 40 + float), 12, AppColors.coral);
        _heartPath(
          c,
          Offset(40, 58 - float),
          7,
          AppColors.coral.withValues(alpha: 0.6),
        );
    }
  }

  // ---------------------------------------------------------------- shapes

  static void _heartPath(Canvas c, Offset center, double size, Color color) {
    final s = size;
    final p = Path()
      ..moveTo(center.dx, center.dy + s * 0.75)
      ..cubicTo(
        center.dx - s * 1.3,
        center.dy - s * 0.1,
        center.dx - s * 0.6,
        center.dy - s * 1.0,
        center.dx,
        center.dy - s * 0.35,
      )
      ..cubicTo(
        center.dx + s * 0.6,
        center.dy - s * 1.0,
        center.dx + s * 1.3,
        center.dy - s * 0.1,
        center.dx,
        center.dy + s * 0.75,
      )
      ..close();
    c.drawPath(p, Paint()..color = color);
  }

  static void _sparkle(Canvas c, Offset o, double r, Color color) {
    final p = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close();
    c.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(MascotPainter old) =>
      old.mood != mood || old.t != t || old.blink != blink;
}
