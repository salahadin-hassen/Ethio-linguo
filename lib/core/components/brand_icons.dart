import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BrandIconKind { flame, xp, heart, gem, leaf, lock, check, crown, star }

/// Custom-drawn icons for gamification so stats feel ownable rather than
/// generic Material glyphs. All vector, no image assets.
class BrandIcon extends StatelessWidget {
  const BrandIcon(this.kind, {super.key, this.size = 24, this.muted = false});

  final BrandIconKind kind;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BrandIconPainter(kind, muted)),
    ),
  );
}

class _BrandIconPainter extends CustomPainter {
  _BrandIconPainter(this.kind, this.muted);

  final BrandIconKind kind;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    Color c(Color v) => muted ? const Color(0xFFCFC6B8) : v;
    switch (kind) {
      case BrandIconKind.flame:
        final outer = Path()
          ..moveTo(12, 1.5)
          ..cubicTo(14, 6, 20, 8.5, 20, 14.5)
          ..cubicTo(20, 19.2, 16.4, 22.5, 12, 22.5)
          ..cubicTo(7.6, 22.5, 4, 19.2, 4, 14.5)
          ..cubicTo(4, 11, 6, 9, 7.5, 7.5)
          ..cubicTo(7.8, 10, 9, 11, 10, 11.2)
          ..cubicTo(9.5, 7, 10.5, 4, 12, 1.5)
          ..close();
        canvas.drawPath(outer, Paint()..color = c(AppColors.coral));
        final inner = Path()
          ..moveTo(12, 11)
          ..cubicTo(13.5, 13.5, 16, 14.5, 16, 17.5)
          ..cubicTo(16, 19.8, 14.2, 21.2, 12, 21.2)
          ..cubicTo(9.8, 21.2, 8, 19.8, 8, 17.5)
          ..cubicTo(8, 15, 10.5, 13.5, 12, 11)
          ..close();
        canvas.drawPath(inner, Paint()..color = c(AppColors.gold));
      case BrandIconKind.xp:
        // Bolt inside a rounded hexagon.
        final hex = Path();
        for (var i = 0; i < 6; i++) {
          final a = math.pi / 6 + i * math.pi / 3;
          final p = Offset(12 + math.cos(a) * 10.5, 12 + math.sin(a) * 10.5);
          i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
        }
        hex.close();
        canvas.drawPath(hex, Paint()..color = c(AppColors.periwinkle));
        canvas.drawPath(
          hex,
          Paint()
            ..color = c(AppColors.periwinkle)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeJoin = StrokeJoin.round,
        );
        final bolt = Path()
          ..moveTo(13.2, 5)
          ..lineTo(7.8, 13)
          ..lineTo(11.4, 13)
          ..lineTo(10.6, 19)
          ..lineTo(16.2, 10.8)
          ..lineTo(12.5, 10.8)
          ..close();
        canvas.drawPath(
          bolt,
          Paint()..color = muted ? Colors.white : AppColors.gold,
        );
      case BrandIconKind.heart:
        final p = Path()
          ..moveTo(12, 21)
          ..cubicTo(4, 15.5, 1.5, 11.5, 2.5, 7.5)
          ..cubicTo(3.5, 3.5, 9, 2.5, 12, 6.5)
          ..cubicTo(15, 2.5, 20.5, 3.5, 21.5, 7.5)
          ..cubicTo(22.5, 11.5, 20, 15.5, 12, 21)
          ..close();
        canvas.drawPath(p, Paint()..color = c(AppColors.coral));
        canvas.drawOval(
          const Rect.fromLTWH(5.5, 6.5, 4, 3),
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
      case BrandIconKind.gem:
        final p = Path()
          ..moveTo(6, 4)
          ..lineTo(18, 4)
          ..lineTo(22, 9.5)
          ..lineTo(12, 21)
          ..lineTo(2, 9.5)
          ..close();
        canvas.drawPath(p, Paint()..color = c(AppColors.teal));
        canvas.drawPath(
          Path()
            ..moveTo(2, 9.5)
            ..lineTo(22, 9.5)
            ..lineTo(12, 21)
            ..close(),
          Paint()..color = c(AppColors.tealShade),
        );
      case BrandIconKind.leaf:
        final p = Path()
          ..moveTo(4, 20)
          ..cubicTo(4, 9, 10, 4, 21, 3)
          ..cubicTo(20, 14, 15, 20, 4, 20)
          ..close();
        canvas.drawPath(p, Paint()..color = c(AppColors.teal));
        canvas.drawLine(
          const Offset(5, 19),
          const Offset(16, 8),
          Paint()
            ..color = c(AppColors.tealShade)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      case BrandIconKind.lock:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4.5, 10, 15, 11),
            const Radius.circular(3),
          ),
          Paint()..color = c(const Color(0xFFB5AC9F)),
        );
        canvas.drawArc(
          const Rect.fromLTWH(7.5, 3.5, 9, 12),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = c(const Color(0xFFB5AC9F))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
        canvas.drawCircle(
          const Offset(12, 15.5),
          1.8,
          Paint()..color = Colors.white,
        );
      case BrandIconKind.check:
        canvas.drawPath(
          Path()
            ..moveTo(5, 12.5)
            ..lineTo(10, 17.5)
            ..lineTo(19.5, 7),
          Paint()
            ..color = c(AppColors.indigo)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case BrandIconKind.crown:
        final p = Path()
          ..moveTo(3, 18)
          ..lineTo(2, 7)
          ..lineTo(8, 11)
          ..lineTo(12, 4)
          ..lineTo(16, 11)
          ..lineTo(22, 7)
          ..lineTo(21, 18)
          ..close();
        canvas.drawPath(p, Paint()..color = c(AppColors.gold));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 18, 18, 3),
            const Radius.circular(1.5),
          ),
          Paint()..color = c(AppColors.goldShade),
        );
      case BrandIconKind.star:
        final p = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? 10.5 : 4.6;
          final a = -math.pi / 2 + i * math.pi / 5;
          final pt = Offset(12 + math.cos(a) * r, 12.5 + math.sin(a) * r);
          i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        p.close();
        canvas.drawPath(
          p,
          Paint()
            ..color = c(AppColors.gold)
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 2
            ..style = PaintingStyle.fill,
        );
    }
  }

  @override
  bool shouldRepaint(_BrandIconPainter old) =>
      old.kind != kind || old.muted != muted;
}
