import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../characters.dart';
import '../rig/character_rig_controller.dart';
import 'puppet_motor.dart';
import 'puppet_painter.dart';
import 'puppet_specs.dart';

/// Interim code-rigged character (Spark, Professor). Driven by the same
/// [CharacterRigController] as the Rive rig. Repaints the CustomPaint only
/// (no widget rebuilds per frame); the ticker stops when off-screen
/// (TickerMode) and the motor drops body travel under reduced motion.
class PuppetCharacter extends StatefulWidget {
  const PuppetCharacter({
    super.key,
    required this.character,
    required this.controller,
    required this.reducedMotion,
  });

  final CastMember character;
  final CharacterRigController controller;
  final bool reducedMotion;

  static bool supports(CastMember m) =>
      m == CastMember.spark || m == CastMember.professor;

  @override
  State<PuppetCharacter> createState() => _PuppetCharacterState();
}

class _PuppetCharacterState extends State<PuppetCharacter>
    with SingleTickerProviderStateMixin {
  late PuppetMotor _motor = _make();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;

  PuppetMotor _make() => PuppetMotor(
    widget.character == CastMember.professor ? ProfessorSpec() : SparkSpec(),
    widget.controller,
  )..reducedMotion = widget.reducedMotion;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onEvent);
    _motor.tick(1 / 60); // first pose before the first frame
    _syncTicker();
  }

  /// Reduced motion: no continuous animation at all — the pose updates
  /// only when a real event changes the controller.
  void _syncTicker() {
    if (widget.reducedMotion) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onEvent() {
    if (widget.reducedMotion) _motor.tick(1 / 60);
  }

  void _onTick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    _motor.tick(dt <= 0 ? 1 / 60 : dt);
  }

  @override
  void didUpdateWidget(PuppetCharacter old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller ||
        old.character != widget.character) {
      old.controller.removeListener(_onEvent);
      widget.controller.addListener(_onEvent);
      _motor.dispose();
      _motor = _make();
    }
    _motor.reducedMotion = widget.reducedMotion;
    _syncTicker();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onEvent);
    _ticker.dispose();
    _motor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: widget.character == CastMember.professor
        ? ProfessorPainter(_motor)
        : SparkPainter(_motor),
    isComplex: true,
    willChange: true,
  );
}
