import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/components/speech_bubble.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/course.dart';
import '../mascot/mascot.dart';
import 'node_actions.dart';
import 'widgets/path_node_button.dart';
import 'widgets/unit_header.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Learning path')),
      body: ListView.builder(
        key: const PageStorageKey('path_list'),
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.xs,
          Space.gutter,
          Space.xxxl,
        ),
        itemCount: app.course.units.length,
        itemBuilder: (context, i) {
          final unit = app.course.units[i];
          final locked = unit.nodes.every(
            (n) => app.stateOf(n) == NodeState.locked,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: Space.xl),
            child: Column(
              children: [
                UnitHeader(
                  unit: unit,
                  progress: app.unitProgress(unit),
                  locked: locked,
                ),
                const SizedBox(height: Space.md),
                _UnitPath(unit: unit),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Lays nodes out on a gentle S-curve and paints connectors behind them.
class _UnitPath extends StatelessWidget {
  const _UnitPath({required this.unit});

  final Unit unit;

  static const _rowHeight = 118.0;
  static const _pattern = [0.0, -0.6, -0.9, -0.5, 0.2, 0.7, 0.9, 0.4];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final amp = (width / 2 - 70).clamp(40.0, 110.0);
        final centers = [
          for (var i = 0; i < unit.nodes.length; i++)
            Offset(
              width / 2 + _pattern[i % _pattern.length] * amp,
              i * _rowHeight + 50,
            ),
        ];
        final states = [for (final n in unit.nodes) app.stateOf(n)];
        return SizedBox(
          height: unit.nodes.length * _rowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConnectorPainter(centers, states, unit.color),
                ),
              ),
              for (var i = 0; i < unit.nodes.length; i++) ...[
                Positioned(
                  left: centers[i].dx - 65,
                  top: centers[i].dy - 50,
                  width: 130,
                  child: Column(
                    children: [
                      PathNodeButton(
                        node: unit.nodes[i],
                        state: states[i],
                        unitColor: unit.color,
                        unitShade: unit.shade,
                        onTap: () => openPathNode(context, unit.nodes[i]),
                      ),
                      // Ivory pill keeps labels legible over connectors.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ivory,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unit.nodes[i].title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(
                            color: states[i] == NodeState.locked
                                ? AppColors.textMuted
                                : AppColors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (states[i] == NodeState.current)
                  Positioned(
                    top: centers[i].dy - 4,
                    left: centers[i].dx < width / 2 ? centers[i].dx + 58 : null,
                    right: centers[i].dx >= width / 2
                        ? width - centers[i].dx + 58
                        : null,
                    child: Column(
                      children: [
                        SpeechBubble(
                          text: unit.nodes[i].kind == NodeKind.checkpoint
                              ? 'Test time!'
                              : 'Start here!',
                          color: AppColors.gold,
                          tail: BubbleTail.bottomLeft,
                          style: AppType.label,
                        ),
                        const Mascot(mood: MascotMood.excited, size: 88),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter(this.centers, this.states, this.color);

  final List<Offset> centers;
  final List<NodeState> states;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < centers.length - 1; i++) {
      final a = centers[i] + const Offset(0, 12);
      final b = centers[i + 1] + const Offset(0, 12);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
      final done = states[i] == NodeState.completed;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = done ? AppColors.gold : AppColors.outline;
      if (done) {
        canvas.drawPath(path, paint);
      } else {
        for (final m in path.computeMetrics()) {
          for (var d = 0.0; d < m.length; d += 18) {
            canvas.drawPath(
              m.extractPath(d, (d + 8).clamp(0, m.length)),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter o) =>
      o.states.toString() != states.toString() ||
      o.centers.toString() != centers.toString();
}
