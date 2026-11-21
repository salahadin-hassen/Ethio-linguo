import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/motion.dart';

/// Tactile "3D" surface: a coloured face sitting on a darker lip that sinks
/// when pressed. Base for buttons, answer tiles and path nodes so every tap
/// gets the same physical feedback.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    required this.shade,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.depth = 4,
    this.border,
    this.shape = BoxShape.rectangle,
    this.haptic = true,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color shade;
  final BorderRadius borderRadius;
  final double depth;
  final BoxBorder? border;
  final BoxShape shape;
  final bool haptic;
  final String? semanticLabel;
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final depth = widget.depth;
    final offset = _down ? depth : 0.0;
    final isCircle = widget.shape == BoxShape.circle;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: enabled
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: Padding(
          padding: EdgeInsets.only(top: offset, bottom: depth - offset),
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: widget.color,
              shape: widget.shape,
              borderRadius: isCircle ? null : widget.borderRadius,
              border: widget.border,
              boxShadow: [
                BoxShadow(
                  color: widget.shade,
                  offset: Offset(0, depth - offset),
                  blurRadius: 0,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
