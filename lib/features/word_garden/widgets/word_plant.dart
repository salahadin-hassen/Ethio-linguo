import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/progress.dart';

/// A word's plant in the Word Garden: seed -> sprout -> bud -> bloom.
/// [thirsty] droops the plant slightly and shows a water-drop cue.
class WordPlant extends StatelessWidget {
  const WordPlant({
    super.key,
    required this.stage,
    this.petal = AppColors.coral,
    this.size = 64,
    this.thirsty = false,
  });

  final GrowthStage stage;
  final Color petal;
  final double size;
  final bool thirsty;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _PlantPainter(stage, petal, thirsty)),
    ),
  );
}

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.stage, this.petal, this.thirsty);

  final GrowthStage stage;
  final Color petal;
  final bool thirsty;

  static const _soil = Color(0xFF8B5E3C);
  static const _soilTop = Color(0xFFA9774E);
  static const _stem = Color(0xFF1C9A8B);
  static const _leaf = AppColors.teal;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    // Soil mound.
    canvas.drawOval(
      const Rect.fromLTWH(10, 50, 44, 12),
      Paint()..color = _soil,
    );
    canvas.drawOval(
      const Rect.fromLTWH(13, 49, 38, 8),
      Paint()..color = _soilTop,
    );

    final lean = thirsty ? 0.18 : 0.0;
    canvas.save();
    canvas.translate(32, 53);
    canvas.rotate(lean);
    final stemPaint = Paint()
      ..color = _stem
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void leaf(double y, double dir, double len) {
      final p = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(
          dir * len * 0.5,
          y - len * 0.75,
          dir * len,
          y - len * 0.2,
        )
        ..quadraticBezierTo(dir * len * 0.5, y + len * 0.15, 0, y)
        ..close();
      canvas.drawPath(p, Paint()..color = _leaf);
    }

    switch (stage) {
      case GrowthStage.seed:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, -2), width: 9, height: 7),
          Paint()..color = const Color(0xFF5B3A22),
        );
        canvas.drawLine(
          const Offset(0, -5),
          const Offset(1.5, -10),
          stemPaint..strokeWidth = 2,
        );
      case GrowthStage.sprout:
        canvas.drawLine(Offset.zero, const Offset(0, -16), stemPaint);
        leaf(-14, -1, 12);
        leaf(-16, 1, 12);
      case GrowthStage.bud:
        canvas.drawLine(Offset.zero, const Offset(0, -28), stemPaint);
        leaf(-10, -1, 13);
        leaf(-16, 1, 12);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, -32), width: 10, height: 13),
          Paint()..color = petal,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-5, -29)
            ..quadraticBezierTo(0, -24, 5, -29)
            ..lineTo(0, -26)
            ..close(),
          Paint()..color = _leaf,
        );
      case GrowthStage.bloom:
        canvas.drawLine(Offset.zero, const Offset(0, -30), stemPaint);
        leaf(-10, -1, 14);
        leaf(-17, 1, 13);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(math.cos(a) * 7, -36 + math.sin(a) * 7),
              width: 10,
              height: 10,
            ),
            Paint()..color = petal,
          );
        }
        canvas.drawCircle(
          const Offset(0, -36),
          5,
          Paint()..color = AppColors.gold,
        );
    }
    canvas.restore();

    if (thirsty) {
      final drop = Path()
        ..moveTo(52, 6)
        ..quadraticBezierTo(58, 14, 55, 17)
        ..quadraticBezierTo(52, 20, 49, 17)
        ..quadraticBezierTo(46, 14, 52, 6)
        ..close();
      canvas.drawPath(drop, Paint()..color = AppColors.periwinkle);
    }
  }

  @override
  bool shouldRepaint(_PlantPainter o) =>
      o.stage != stage || o.petal != petal || o.thirsty != thirsty;
}
