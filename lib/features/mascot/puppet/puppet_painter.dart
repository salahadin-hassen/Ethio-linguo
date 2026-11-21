import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'puppet_motor.dart';

// Vector puppets drawn from articulated parts (interim, until Rive rigs).
// Design space 200 x 240; feet are planted at y = 232 — the character never
// moves as a whole image.

const _ink = Color(0xFF231B2E);
const _line = 3.0;

class PuppetPalette {
  const PuppetPalette({
    required this.skin,
    required this.skinShade,
    required this.sleeve,
    required this.sleeveShade,
    required this.pants,
    required this.shoes,
    required this.sole,
  });
  final Color skin, skinShade, sleeve, sleeveShade, pants, shoes, sole;
}

abstract class PuppetPainter extends CustomPainter {
  PuppetPainter(this.motor) : super(repaint: motor);
  final PuppetMotor motor;

  PuppetPalette get palette;
  double get headR;

  // Character-specific parts.
  void paintTorso(Canvas c, Rect torso, PuppetPose p);
  void paintHairBack(Canvas c, PuppetPose p) {}
  void paintHairFront(Canvas c, PuppetPose p);
  void paintFaceExtras(Canvas c, PuppetPose p, double tx, double fy) {}
  void paintNeckwear(Canvas c, Offset neck, PuppetPose p) {}
  Color get browColor => _ink;
  double get browWidth => 5;
  double get eyeRx;
  double get eyeRy;
  double get eyeSpacing;

  final _fill = Paint()..style = PaintingStyle.fill;
  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _line
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = _ink;

  void shape(
    Canvas c,
    Path path,
    Color color, {
    Color? shade,
    Path? shadePath,
  }) {
    c.drawPath(path, _fill..color = color);
    if (shade != null && shadePath != null) {
      c.save();
      c.clipPath(path);
      c.drawPath(shadePath, _fill..color = shade);
      c.restore();
    }
    c.drawPath(path, _stroke);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = motor.pose;
    final s = math.min(size.width / 200, size.height / 240);
    canvas.save();
    canvas.translate((size.width - 200 * s) / 2, size.height - 240 * s);
    canvas.scale(s);

    // Ground shadow.
    canvas.drawOval(
      const Rect.fromLTWH(52, 226, 96, 12),
      _fill..color = const Color(0x22000000),
    );

    final knee = p[Ch.kneeBend];
    final hipX = 100 + p[Ch.hipShift];
    final hipY = 190 + knee * 7;
    _legs(canvas, hipX, hipY, knee);

    // Upper body pivots at the hips (lean), breathing deforms the torso.
    canvas.save();
    canvas.translate(hipX, hipY);
    canvas.rotate(p[Ch.torsoLean]);
    canvas.translate(-hipX, -hipY);
    final torsoTop = 128 + knee * 7 - p.breath * 2.4;
    final torso = Rect.fromLTRB(hipX - 37, torsoTop, hipX + 37, hipY + 4);
    final shL = Offset(hipX - 33, torsoTop + 9 - p[Ch.shoulderL] * 3.2);
    final shR = Offset(hipX + 33, torsoTop + 9 - p[Ch.shoulderR] * 3.2);
    final neck = Offset(hipX, torsoTop + 1);

    // Arms raised high go behind the head? Keep in front for readability.
    paintTorso(canvas, torso, p);
    paintNeckwear(canvas, neck, p);
    _head(canvas, neck, p);
    _arm(canvas, shL, p[Ch.armLUp], p[Ch.armLLow], left: true, hand: p.handL);
    _arm(canvas, shR, p[Ch.armRUp], p[Ch.armRLow], left: false, hand: p.handR);
    canvas.restore();
    canvas.restore();
  }

  void _legs(Canvas c, double hipX, double hipY, double knee) {
    final pal = palette;
    for (final side in [-1.0, 1.0]) {
      final top = Offset(hipX + side * 14, hipY - 4);
      final foot = Offset(100 + side * (16 + knee * 6), 224);
      final kneeP = Offset(
        (top.dx + foot.dx) / 2 + side * knee * 7,
        (top.dy + foot.dy) / 2,
      );
      final leg = Path()
        ..moveTo(top.dx - 10, top.dy)
        ..lineTo(top.dx + 10, top.dy)
        ..lineTo(kneeP.dx + 9, kneeP.dy)
        ..lineTo(foot.dx + 8, foot.dy)
        ..lineTo(foot.dx - 8, foot.dy)
        ..lineTo(kneeP.dx - 9, kneeP.dy)
        ..close();
      shape(c, leg, pal.pants);
      final shoe = RRect.fromRectAndCorners(
        Rect.fromLTRB(
          foot.dx - 14 + side * 2,
          foot.dy - 4,
          foot.dx + 14 + side * 2,
          233,
        ),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      );
      shape(c, Path()..addRRect(shoe), pal.shoes);
      c.drawLine(
        Offset(shoe.left + 2, 229),
        Offset(shoe.right - 2, 229),
        Paint()
          ..color = pal.sole
          ..strokeWidth = 3,
      );
    }
  }

  Offset _dir(double a, bool left) =>
      Offset(left ? -math.sin(a) : math.sin(a), math.cos(a));

  void _arm(
    Canvas c,
    Offset sh,
    double up,
    double low, {
    required bool left,
    required Hand hand,
  }) {
    final pal = palette;
    final elbow = sh + _dir(up, left) * 29;
    final wrist = elbow + _dir(up + low, left) * 27;
    final limb = Path()
      ..moveTo(sh.dx, sh.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(wrist.dx, wrist.dy);
    c.drawPath(
      limb,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 17 + _line * 2
        ..color = _ink,
    );
    c.drawPath(
      limb,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 17
        ..color = pal.sleeve,
    );
    // Cuff.
    final cuffDir = (wrist - elbow) / (wrist - elbow).distance;
    c.drawLine(
      wrist - cuffDir * 4 + Offset(-cuffDir.dy, cuffDir.dx) * 8,
      wrist - cuffDir * 4 - Offset(-cuffDir.dy, cuffDir.dx) * 8,
      Paint()
        ..color = pal.sleeveShade
        ..strokeWidth = 3,
    );
    _hand(c, wrist + cuffDir * 4, cuffDir, hand, left);
  }

  void _hand(Canvas c, Offset at, Offset dir, Hand hand, bool left) {
    final skin = palette.skin;
    final ang = math.atan2(dir.dy, dir.dx);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(ang - math.pi / 2);
    final palm = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: 8.5));
    switch (hand) {
      case Hand.open || Hand.wave:
        final p = Path()
          ..addOval(
            Rect.fromCenter(center: const Offset(0, 3), width: 19, height: 17),
          );
        for (var i = -1; i <= 1; i++) {
          p.addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(i * 5.5, 13),
                width: 5.5,
                height: 11,
              ),
              const Radius.circular(3),
            ),
          );
        }
        p.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(left ? 9 : -9, 2),
              width: 9,
              height: 5,
            ),
            const Radius.circular(3),
          ),
        );
        shape(c, Path.combine(PathOperation.union, p, palm), skin);
      case Hand.point:
        final p = Path.combine(
          PathOperation.union,
          palm,
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: const Offset(0, 13),
                width: 5.5,
                height: 16,
              ),
              const Radius.circular(3),
            ),
          ),
        );
        shape(c, p, skin);
      case Hand.thumb:
        final p = Path.combine(
          PathOperation.union,
          Path()..addOval(
            Rect.fromCenter(center: Offset.zero, width: 18, height: 15),
          ),
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(left ? 7 : -7, -2),
                width: 6,
                height: 15,
              ),
              const Radius.circular(3),
            )..shift(const Offset(0, 0)),
          ),
        );
        c.rotate(math.pi);
        shape(c, p, skin);
      case Hand.fist:
        shape(
          c,
          Path()..addOval(
            Rect.fromCenter(center: Offset.zero, width: 19, height: 17),
          ),
          skin,
        );
        c.drawLine(
          const Offset(-4, -2),
          const Offset(4, -2),
          _stroke..strokeWidth = 1.6,
        );
        _stroke.strokeWidth = _line;
      case Hand.chin:
        shape(
          c,
          Path()..addOval(
            Rect.fromCenter(center: Offset.zero, width: 19, height: 16),
          ),
          skin,
        );
      case Hand.relaxed:
        shape(c, palm, skin);
    }
    c.restore();
  }

  void _head(Canvas c, Offset neck, PuppetPose p) {
    final pal = palette;
    // Neck.
    final neckRect = Rect.fromCenter(
      center: neck + const Offset(0, -5),
      width: 18,
      height: 14,
    );
    shape(c, Path()..addRect(neckRect), pal.skinShade);

    c.save();
    c.translate(neck.dx, neck.dy - 2);
    c.rotate(p[Ch.headRot]);
    final nod = p[Ch.headNod];
    final center = Offset(0, -headR + 4 + nod * 4);
    c.translate(center.dx, center.dy);

    paintHairBack(c, p);
    // Ears (parallax opposite to face turn).
    final turn = p[Ch.headTurn];
    for (final side in [-1.0, 1.0]) {
      final ex = side * (headR - 3) - turn * 3;
      shape(
        c,
        Path()..addOval(
          Rect.fromCenter(center: Offset(ex, 6), width: 16, height: 20),
        ),
        pal.skin,
      );
    }
    final face = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: headR * 2,
          height: headR * 1.92,
        ),
      );
    shape(
      c,
      face,
      pal.skin,
      shade: pal.skinShade,
      shadePath: Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(headR * 0.55, headR * 0.35),
            width: headR * 1.3,
            height: headR * 1.5,
          ),
        ),
    );

    final tx = turn * 9;
    final fy = nod * 5; // features slide down on a nod (perspective)
    _cheeks(c, p, tx, fy);
    _eyes(c, p, tx, fy);
    _brows(c, p, tx, fy);
    // Nose.
    c.drawArc(
      Rect.fromCenter(center: Offset(tx * 1.2, 12 + fy), width: 9, height: 7),
      0.2,
      math.pi - 0.4,
      false,
      _stroke..strokeWidth = 2.2,
    );
    _stroke.strokeWidth = _line;
    _mouth(c, p, tx, fy);
    paintFaceExtras(c, p, tx, fy);
    c.rotate(p[Ch.hair]);
    paintHairFront(c, p);
    c.restore();
  }

  void _cheeks(Canvas c, PuppetPose p, double tx, double fy) {
    final a = (0.25 + p[Ch.cheek] * 0.35).clamp(0.0, 0.7);
    for (final side in [-1.0, 1.0]) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(side * headR * 0.58 + tx, 16 + fy - p[Ch.cheek] * 2),
          width: 16,
          height: 10,
        ),
        _fill..color = const Color(0xFFFF7A6B).withValues(alpha: a),
      );
    }
  }

  void _eyes(Canvas c, PuppetPose p, double tx, double fy) {
    final happy = p[Ch.eyeHappy].clamp(0.0, 1.0);
    final wide = p[Ch.lidWide].clamp(0.0, 1.0);
    for (final side in [-1.0, 1.0]) {
      final ctr = Offset(side * eyeSpacing + tx, -2 + fy);
      final rx = eyeRx * (1 + wide * 0.12);
      final ry = eyeRy * (1 + wide * 0.18);
      if (happy > 0.55) {
        // Laughing "^" eyes.
        final arc = Path()
          ..moveTo(ctr.dx - rx, ctr.dy + 2)
          ..quadraticBezierTo(
            ctr.dx,
            ctr.dy - ry * 1.1,
            ctr.dx + rx,
            ctr.dy + 2,
          );
        c.drawPath(arc, _stroke..strokeWidth = 3.4);
        _stroke.strokeWidth = _line;
        continue;
      }
      final eye = Rect.fromCenter(center: ctr, width: rx * 2, height: ry * 2);
      final eyePath = Path()..addOval(eye);
      c.drawPath(eyePath, _fill..color = Colors.white);
      c.save();
      c.clipPath(eyePath);
      final pupil =
          ctr + Offset(p[Ch.pupilX] * rx * 0.42, p[Ch.pupilY] * ry * 0.35);
      final pr = math.min(rx, ry) * 0.62;
      c.drawCircle(pupil, pr, _fill..color = const Color(0xFF2B1D17));
      c.drawCircle(
        pupil + Offset(-pr * 0.35, -pr * 0.4),
        pr * 0.32,
        _fill..color = Colors.white,
      );
      // Lids: blink + squint from smiles/happiness, as skin closing from top.
      final lid = math.max(
        side < 0 ? p.lidL : p.lidR,
        (happy * 0.5 + (p[Ch.mouthSmile] > 0.8 ? 0.12 : 0)).clamp(0.0, 0.6),
      );
      if (lid > 0.01) {
        final h = eye.height * lid;
        c.drawRect(
          Rect.fromLTWH(eye.left - 2, eye.top - 2, eye.width + 4, h + 2),
          _fill..color = palette.skin,
        );
        c.drawLine(
          Offset(eye.left, eye.top + h),
          Offset(eye.right, eye.top + h),
          _stroke..strokeWidth = 2.4,
        );
        _stroke.strokeWidth = _line;
      }
      c.restore();
      c.drawPath(eyePath, _stroke..strokeWidth = 2.6);
      _stroke.strokeWidth = _line;
    }
  }

  void _brows(Canvas c, PuppetPose p, double tx, double fy) {
    final paint = Paint()
      ..color = browColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = browWidth;
    for (final side in [-1.0, 1.0]) {
      final raise = side < 0 ? p[Ch.browL] : p[Ch.browR];
      final furrow = p[Ch.browFurrow];
      final y = -2 - eyeRy - 7 + fy - raise * 6;
      final inner = Offset(
        side * (eyeSpacing - eyeRx * 0.8) + tx,
        y + furrow * 4,
      );
      final outer = Offset(
        side * (eyeSpacing + eyeRx * 0.9) + tx,
        y - furrow * 1.5 + 1,
      );
      final mid = Offset((inner.dx + outer.dx) / 2, y - 3 - raise * 1.5);
      c.drawPath(
        Path()
          ..moveTo(inner.dx, inner.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, outer.dx, outer.dy),
        paint,
      );
    }
  }

  void _mouth(Canvas c, PuppetPose p, double tx, double fy) {
    final open = p[Ch.mouthOpen].clamp(0.0, 1.0);
    final smile = p[Ch.mouthSmile].clamp(-1.0, 1.0);
    final round = p[Ch.mouthRound].clamp(0.0, 1.0);
    final ctr = Offset(tx * 1.1, 27 + fy);
    final w = (19 + smile * 5) * (1 - round * 0.5);
    final curve = smile * 7;
    if (open < 0.06) {
      c.drawPath(
        Path()
          ..moveTo(ctr.dx - w / 2, ctr.dy - curve * 0.3)
          ..quadraticBezierTo(
            ctr.dx,
            ctr.dy + curve,
            ctr.dx + w / 2,
            ctr.dy - curve * 0.3,
          ),
        _stroke..strokeWidth = 2.8,
      );
      _stroke.strokeWidth = _line;
      return;
    }
    final h = 4 + open * 16;
    final top = ctr.dy - curve * 0.3 - h * 0.25;
    final mouth = Path()
      ..moveTo(ctr.dx - w / 2, top)
      ..quadraticBezierTo(ctr.dx, top + curve * 0.4 - 1, ctr.dx + w / 2, top)
      ..quadraticBezierTo(
        ctr.dx + w / 2 * (0.9 - round * 0.3),
        top + h,
        ctr.dx,
        top + h + curve * 0.3,
      )
      ..quadraticBezierTo(
        ctr.dx - w / 2 * (0.9 - round * 0.3),
        top + h,
        ctr.dx - w / 2,
        top,
      )
      ..close();
    c.drawPath(mouth, _fill..color = const Color(0xFF6E1F2A));
    c.save();
    c.clipPath(mouth);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(ctr.dx, top + h + 2),
        width: w * 0.7,
        height: h * 0.8,
      ),
      _fill..color = const Color(0xFFE8737B),
    );
    if (smile > 0.4) {
      c.drawRect(
        Rect.fromLTWH(ctr.dx - w / 2, top - 1, w, 3.5),
        _fill..color = Colors.white,
      );
    }
    c.restore();
    c.drawPath(mouth, _stroke..strokeWidth = 2.6);
    _stroke.strokeWidth = _line;
  }

  @override
  bool shouldRepaint(covariant PuppetPainter old) => old.motor != motor;
}

/// Spark: coral jacket, yellow tee, jeans, flat-top hair with a stripe.
class SparkPainter extends PuppetPainter {
  SparkPainter(super.motor);

  @override
  final palette = const PuppetPalette(
    skin: Color(0xFF7B4A2D),
    skinShade: Color(0xFF6A3E25),
    sleeve: Color(0xFFF26B5B),
    sleeveShade: Color(0xFFC94E40),
    pants: Color(0xFF3D5AA8),
    shoes: Color(0xFFF5C451),
    sole: Color(0xFFFFFFFF),
  );
  @override
  double get headR => 46;
  @override
  double get eyeRx => 10;
  @override
  double get eyeRy => 12;
  @override
  double get eyeSpacing => 18;

  @override
  void paintTorso(Canvas c, Rect t, PuppetPose p) {
    final body = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(t.left, t.top, t.right, t.bottom),
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: const Radius.circular(12),
          bottomRight: const Radius.circular(12),
        ),
      );
    shape(
      c,
      body,
      palette.sleeve,
      shade: palette.sleeveShade,
      shadePath: Path()
        ..addRect(Rect.fromLTRB(t.right - 16, t.top, t.right, t.bottom)),
    );
    // Yellow tee panel + zip line.
    final tee = Path()
      ..addRect(
        Rect.fromLTRB(
          t.center.dx - 12,
          t.top + 4,
          t.center.dx + 12,
          t.bottom - 12,
        ),
      );
    shape(c, tee, const Color(0xFFF5C451));
    // Belt band with dots (brand pattern).
    final belt = Rect.fromLTRB(
      t.left + 2,
      t.bottom - 13,
      t.right - 2,
      t.bottom - 3,
    );
    shape(c, Path()..addRect(belt), Colors.white);
    const dots = [
      Color(0xFFF26B5B),
      Color(0xFF20B8A6),
      Color(0xFF7183F5),
      Color(0xFFF5C451),
    ];
    for (var i = 0; i < 7; i++) {
      c.drawCircle(
        Offset(belt.left + 8 + i * (belt.width - 16) / 6, belt.center.dy),
        2.4,
        _fill..color = dots[i % dots.length],
      );
    }
  }

  @override
  void paintHairFront(Canvas c, PuppetPose p) {
    final hair = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(-40, -headR - 30, 40, -headR + 22),
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        ),
      );
    shape(c, hair, const Color(0xFF1E1A1D));
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF4A3F45);
    for (var row = 0; row < 4; row++) {
      final y = -headR - 22 + row * 10.0;
      final path = Path()..moveTo(-34, y);
      for (var x = -34.0; x < 34; x += 8) {
        path.quadraticBezierTo(x + 4, y - 3, x + 8, y);
      }
      c.drawPath(path, wave);
    }
    // Signature lightning stripe.
    c.drawPath(
      Path()
        ..moveTo(-30, -headR - 20)
        ..lineTo(-24, -headR - 8)
        ..lineTo(-30, -headR - 4)
        ..lineTo(-22, -headR + 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFB07A3E),
    );
  }
}

/// The Professor: cloud of white hair, gold glasses on the hair, white
/// brows and moustache, green waistcoat, patterned scarf.
class ProfessorPainter extends PuppetPainter {
  ProfessorPainter(super.motor);

  @override
  final palette = const PuppetPalette(
    skin: Color(0xFF8D5B3C),
    skinShade: Color(0xFF7A4D32),
    sleeve: Color(0xFF1E6A57),
    sleeveShade: Color(0xFF155344),
    pants: Color(0xFF2C2F48),
    shoes: Color(0xFF4A2E22),
    sole: Color(0xFF2A1A14),
  );
  @override
  double get headR => 42;
  @override
  double get eyeRx => 8;
  @override
  double get eyeRy => 9;
  @override
  double get eyeSpacing => 16;
  @override
  Color get browColor => const Color(0xFFF1F1F5);
  @override
  double get browWidth => 6.5;

  static const _cloud = Color(0xFFF4F4F8);
  static const _cloudShade = Color(0xFFCFCFDD);

  @override
  void paintTorso(Canvas c, Rect t, PuppetPose p) {
    final body = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          t,
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        ),
      );
    shape(
      c,
      body,
      palette.sleeve,
      shade: palette.sleeveShade,
      shadePath: Path()
        ..addRect(Rect.fromLTRB(t.right - 14, t.top, t.right, t.bottom)),
    );
    // Shirt V + buttons.
    final shirt = Path()
      ..moveTo(t.center.dx - 13, t.top + 2)
      ..lineTo(t.center.dx + 13, t.top + 2)
      ..lineTo(t.center.dx + 6, t.bottom - 6)
      ..lineTo(t.center.dx - 6, t.bottom - 6)
      ..close();
    shape(c, shirt, Colors.white);
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
        Offset(t.center.dx + 10, t.top + 22 + i * 12),
        2.2,
        _fill..color = const Color(0xFFF5C451),
      );
    }
  }

  @override
  void paintNeckwear(Canvas c, Offset neck, PuppetPose p) {
    // Scarf ends hang and lag behind body/head motion (secondary).
    final lag = p[Ch.hair] * 30 + p[Ch.torsoLean] * -20;
    for (final side in [-1.0, 1.0]) {
      final top = neck + Offset(side * 9, 0);
      final end = neck + Offset(side * 12 + lag, 52);
      final scarf = Path()
        ..moveTo(top.dx - 6, top.dy)
        ..lineTo(top.dx + 6, top.dy)
        ..lineTo(end.dx + 6, end.dy)
        ..lineTo(end.dx - 6, end.dy)
        ..close();
      shape(c, scarf, Colors.white);
      for (var i = 1; i < 4; i++) {
        final m = Offset.lerp(top, end, i / 4)!;
        c.drawRect(
          Rect.fromCenter(center: m, width: 4, height: 4),
          _fill..color = const Color(0xFFD64545),
        );
      }
    }
  }

  @override
  void paintHairBack(Canvas c, PuppetPose p) {
    for (final (o, r) in [
      (const Offset(-44, -6), 18.0),
      (const Offset(46, -4), 17.0),
      (const Offset(-38, -32), 22.0),
      (const Offset(40, -30), 22.0),
    ]) {
      shape(c, Path()..addOval(Rect.fromCircle(center: o, radius: r)), _cloud);
    }
  }

  @override
  void paintHairFront(Canvas c, PuppetPose p) {
    final cloud = Path();
    for (final (o, r) in [
      (const Offset(-26, -44), 20.0),
      (const Offset(-4, -52), 22.0),
      (const Offset(20, -48), 21.0),
      (const Offset(36, -34), 15.0),
      (const Offset(-38, -28), 14.0),
    ]) {
      cloud.addOval(Rect.fromCircle(center: o, radius: r));
    }
    final merged = Path.combine(PathOperation.union, cloud, Path());
    shape(
      c,
      merged,
      _cloud,
      shade: _cloudShade,
      shadePath: Path()..addRect(const Rect.fromLTRB(-60, -40, 60, -20)),
    );
    // Gold glasses perched on the hair.
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFE2B33C);
    c.drawOval(const Rect.fromLTWH(-24, -50, 18, 11), gold);
    c.drawOval(const Rect.fromLTWH(6, -50, 18, 11), gold);
    c.drawLine(const Offset(-6, -45), const Offset(6, -45), gold);
  }

  @override
  void paintFaceExtras(Canvas c, PuppetPose p, double tx, double fy) {
    // Moustache lifts with an open mouth / smile.
    final lift = p[Ch.mouthOpen] * 3 + p[Ch.mouthSmile] * 1.5;
    final y = 21 + fy - lift;
    final m = Path()
      ..moveTo(tx, y - 2)
      ..cubicTo(tx - 6, y - 6, tx - 18, y - 4, tx - 19, y + 4)
      ..cubicTo(tx - 12, y + 2, tx - 5, y + 4, tx, y + 1)
      ..cubicTo(tx + 5, y + 4, tx + 12, y + 2, tx + 19, y + 4)
      ..cubicTo(tx + 18, y - 4, tx + 6, y - 6, tx, y - 2)
      ..close();
    shape(c, m, _cloud);
    // Small beard under the lip.
    final by = 34 + fy + p[Ch.mouthOpen] * 9;
    shape(
      c,
      Path()..addOval(
        Rect.fromCenter(center: Offset(tx, by), width: 12, height: 8),
      ),
      _cloud,
    );
  }
}
