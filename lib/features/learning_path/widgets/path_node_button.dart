import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/components/brand_icons.dart';
import '../../../core/components/pressable.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/course.dart';

/// A lesson node on the learning path. Completed = gold with check,
/// current = unit colour with a pulsing halo, locked = muted with lock.
class PathNodeButton extends StatefulWidget {
  const PathNodeButton({
    super.key,
    required this.node,
    required this.state,
    required this.unitColor,
    required this.unitShade,
    required this.onTap,
    this.size = 76,
  });

  final PathNode node;
  final NodeState state;
  final Color unitColor;
  final Color unitShade;
  final VoidCallback onTap;
  final double size;

  @override
  State<PathNodeButton> createState() => _PathNodeButtonState();
}

class _PathNodeButtonState extends State<PathNodeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PathNodeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.state == NodeState.current && !Motion.reduced(context);
    if (run && !_pulse.isAnimating) _pulse.repeat();
    if (!run && _pulse.isAnimating) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final checkpoint = widget.node.kind == NodeKind.checkpoint;
    final (Color fill, Color shade) = switch (widget.state) {
      NodeState.completed => (AppColors.gold, AppColors.goldShade),
      NodeState.current => (widget.unitColor, widget.unitShade),
      NodeState.locked => (AppColors.disabledFill, AppColors.outlineStrong),
    };
    final icon = switch ((widget.state, widget.node.kind)) {
      (NodeState.locked, _) => const BrandIcon(BrandIconKind.lock, size: 30),
      (NodeState.completed, NodeKind.checkpoint) => const BrandIcon(
        BrandIconKind.crown,
        size: 34,
      ),
      (NodeState.completed, _) => const BrandIcon(
        BrandIconKind.check,
        size: 34,
      ),
      (_, NodeKind.checkpoint) => const Icon(
        Icons.flag_rounded,
        color: AppColors.indigo,
        size: 34,
      ),
      (_, NodeKind.practice) => const Icon(
        Icons.replay_rounded,
        color: AppColors.indigo,
        size: 34,
      ),
      (_, NodeKind.lesson) => const BrandIcon(BrandIconKind.star, size: 34),
    };
    final stateLabel = switch (widget.state) {
      NodeState.completed => 'completed',
      NodeState.current => 'current lesson, tap to start',
      NodeState.locked => 'locked',
    };
    return SizedBox.square(
      dimension: s + 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.state == NodeState.current)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) {
                final v = _pulse.value;
                return Container(
                  width: s + 4 + v * 18,
                  height: s + 4 + v * 18,
                  decoration: BoxDecoration(
                    shape: checkpoint ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: checkpoint
                        ? BorderRadius.circular(26 + v * 6)
                        : null,
                    border: Border.all(
                      color: widget.unitColor.withValues(alpha: (1 - v) * 0.6),
                      width: 4,
                    ),
                  ),
                );
              },
            ),
          SizedBox.square(
            dimension: s,
            child: Pressable(
              onTap: widget.onTap,
              color: fill,
              shade: shade,
              depth: 6,
              shape: checkpoint ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: BorderRadius.circular(24),
              semanticLabel: '${widget.node.title}, $stateLabel',
              child: Center(child: icon),
            ),
          ),
        ],
      ),
    );
  }
}
