import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Decorative woven band inspired by tibeb — the patterned borders of
/// Ethiopian handwoven cloth. Used sparingly as a cultural signature
/// (headers, celebration cards), never as noise behind text.
class TibebBand extends StatelessWidget {
  const TibebBand({super.key, this.height = 10, this.colors});

  final double height;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TibebPainter(
          colors ??
              const [
                AppColors.coral,
                AppColors.gold,
                AppColors.teal,
                AppColors.periwinkle,
              ],
        ),
      ),
    ),
  );
}

class _TibebPainter extends CustomPainter {
  _TibebPainter(this.colors);
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final unit = h * 1.6;
    var i = 0;
    // Thin rails.
    final rail = Paint()..color = AppColors.indigo.withValues(alpha: 0.85);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h * 0.12), rail);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.88, size.width, h * 0.12), rail);
    for (var x = 0.0; x < size.width; x += unit) {
      final cx = x + unit / 2;
      final cy = h / 2;
      final r = h * 0.32;
      final d = Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx + r * 1.4, cy)
        ..lineTo(cx, cy + r)
        ..lineTo(cx - r * 1.4, cy)
        ..close();
      canvas.drawPath(d, Paint()..color = colors[i % colors.length]);
      canvas.drawCircle(Offset(x, cy), h * 0.08, rail);
      i++;
    }
  }

  @override
  bool shouldRepaint(_TibebPainter old) => false;
}
