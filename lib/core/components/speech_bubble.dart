import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BubbleTail { bottomLeft, bottomRight, left, none }

/// Speech bubble — the brand's visual metaphor for communication.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.color = AppColors.surface,
    this.textColor = AppColors.indigo,
    this.tail = BubbleTail.bottomLeft,
    this.style,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.border = true,
  });

  final String text;
  final Color color;
  final Color textColor;
  final BubbleTail tail;
  final TextStyle? style;
  final EdgeInsets padding;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(color, tail, border),
      child: Padding(
        padding: padding.add(
          EdgeInsets.only(
            bottom:
                tail == BubbleTail.bottomLeft || tail == BubbleTail.bottomRight
                ? 8
                : 0,
            left: tail == BubbleTail.left ? 8 : 0,
          ),
        ),
        child: Text(
          text,
          style: (style ?? AppType.label).copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.color, this.tail, this.border);
  final Color color;
  final BubbleTail tail;
  final bool border;

  @override
  void paint(Canvas canvas, Size size) {
    final bottomInset =
        tail == BubbleTail.bottomLeft || tail == BubbleTail.bottomRight
        ? 8.0
        : 0.0;
    final leftInset = tail == BubbleTail.left ? 8.0 : 0.0;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(leftInset, 0, size.width, size.height - bottomInset),
      const Radius.circular(16),
    );
    final path = Path()..addRRect(body);
    switch (tail) {
      case BubbleTail.bottomLeft:
        path.addPath(
          Path()
            ..moveTo(16, size.height - bottomInset - 1)
            ..lineTo(14, size.height)
            ..lineTo(30, size.height - bottomInset - 1)
            ..close(),
          Offset.zero,
        );
      case BubbleTail.bottomRight:
        path.addPath(
          Path()
            ..moveTo(size.width - 30, size.height - bottomInset - 1)
            ..lineTo(size.width - 14, size.height)
            ..lineTo(size.width - 16, size.height - bottomInset - 1)
            ..close(),
          Offset.zero,
        );
      case BubbleTail.left:
        final cy = size.height / 2;
        path.addPath(
          Path()
            ..moveTo(leftInset + 1, cy - 8)
            ..lineTo(0, cy + 4)
            ..lineTo(leftInset + 1, cy + 6)
            ..close(),
          Offset.zero,
        );
      case BubbleTail.none:
        break;
    }
    canvas.drawShadow(path, AppColors.indigo.withValues(alpha: 0.25), 3, false);
    canvas.drawPath(path, Paint()..color = color);
    if (border) {
      canvas.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.outline,
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter o) => o.color != color || o.tail != tail;
}
