// ignore_for_file: deprecated_member_use
// State-machine inputs are Rive's documented fallback when a rig has no
// view model; data binding is always tried first.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart' as rive;

import '../characters.dart';
import 'character_rig_controller.dart';
import 'rig_contract.dart';

/// Which rig files are actually bundled (checked once via the manifest, so
/// the native Rive runtime is only initialised when a rig exists).
abstract final class RigAssets {
  static Future<Set<String>>? _bundled;

  static Future<bool> available(CastMember m) async {
    final spec = RigContract.specs[m];
    if (spec == null) return false;
    _bundled ??= AssetManifest.loadFromAssetBundle(rootBundle)
        .then((mf) => mf.listAssets().toSet())
        .catchError((_) => <String>{});
    return (await _bundled!).contains(spec.asset);
  }

  @visibleForTesting
  static void reset() => _bundled = null;
}

/// Renders a rigged Rive character and mirrors [controller] into its state
/// machine inputs (names from [RigContract]). Missing inputs are reported
/// once in debug so designer/engineer mismatches surface immediately.
class RiveCharacter extends StatefulWidget {
  const RiveCharacter({
    super.key,
    required this.spec,
    required this.controller,
    required this.reducedMotion,
    required this.fallback,
  });

  final RigSpec spec;
  final CharacterRigController controller;
  final bool reducedMotion;

  /// Shown while loading or if the rig fails to load.
  final Widget fallback;

  @override
  State<RiveCharacter> createState() => _RiveCharacterState();
}

class _RiveCharacterState extends State<RiveCharacter> {
  static Future<bool>? _init;
  rive.File? _file;
  rive.RiveWidgetController? _rc;

  /// Preferred: data binding (the default view model instance, properties
  /// named per RigContract). Fallback: state-machine inputs (deprecated by
  /// Rive but still supported). The rig may use either.
  rive.ViewModelInstance? _vm;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
    widget.controller.addListener(_push);
  }

  Future<void> _load() async {
    try {
      _init ??= rive.RiveNative.init();
      if (!await _init!) throw StateError('Rive native runtime unavailable');
      final bytes = await rootBundle.load(widget.spec.asset);
      final file = await rive.File.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        riveFactory: rive.Factory.rive,
      );
      if (file == null) {
        throw StateError('Could not decode ${widget.spec.asset}');
      }
      final rc = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName(widget.spec.artboard),
        stateMachineSelector: rive.StateMachineSelector.byName(
          widget.spec.stateMachine,
        ),
      );
      if (!mounted) {
        rc.dispose();
        file.dispose();
        return;
      }
      rive.ViewModelInstance? vm;
      try {
        vm = rc.dataBind(rive.DataBind.auto());
      } catch (_) {
        vm = null; // rig drives the state machine with inputs instead
      }
      setState(() {
        _file = file;
        _rc = rc;
        _vm = vm;
      });
      _reportMissingInputs(rc.stateMachine);
      _push();
    } catch (e) {
      debugPrint('rig: ${widget.spec.asset} unavailable ($e); using fallback');
      if (mounted) setState(() => _failed = true);
    }
  }

  // (state-machine inputs are the documented fallback when a rig has no
  // view model; data binding is used first.)
  void _reportMissingInputs(rive.StateMachine sm) {
    if (!kDebugMode) return;
    final vm = _vm;
    final missing = [
      for (final n in RigContract.numbers)
        if ((vm?.number(n) ?? sm.number(n)) == null) n,
      for (final b in RigContract.booleans)
        if ((vm?.boolean(b) ?? sm.boolean(b)) == null) b,
      for (final t in RigContract.triggers)
        if ((vm?.trigger(t) ?? sm.trigger(t)) == null) t,
    ];
    if (missing.isNotEmpty) {
      debugPrint('rig: ${widget.spec.stateMachine} lacks inputs: $missing');
    }
  }

  /// Mirror controller -> state machine. Cheap: only touches inputs.
  void _push() {
    final sm = _rc?.stateMachine;
    if (sm == null) return;
    final c = widget.controller;
    final vm = _vm;
    void n(String name, double v) {
      final p = vm?.number(name);
      if (p != null) {
        p.value = v;
      } else {
        sm.number(name)?.value = v;
      }
    }

    void b(String name, bool v) {
      final p = vm?.boolean(name);
      if (p != null) {
        p.value = v;
      } else {
        sm.boolean(name)?.value = v;
      }
    }

    n(RigContract.emotion, c.emotion.index.toDouble());
    n(RigContract.gazeX, c.gazeX);
    n(RigContract.gazeY, c.gazeY);
    n(RigContract.idleVariant, c.idleVariant.toDouble());
    n(RigContract.voiceAmplitude, c.voiceAmplitude ?? 0);
    n(RigContract.mouthOpen, c.speaking ? (c.voiceAmplitude ?? 0) : 0);
    b(RigContract.isListening, c.listening);
    b(RigContract.isSpeaking, c.speaking);
    b(RigContract.isThinking, c.thinking);
    b(RigContract.isHappy, c.happy);
    b(RigContract.reducedMotion, widget.reducedMotion);
    // Reduced motion: the rig holds a still body (reducedMotion input) and
    // body gestures are not fired; expression changes still come through
    // the emotion number. Triggers are drained either way.
    final triggers = c.drainTriggers();
    if (widget.reducedMotion) return;
    for (final t in triggers) {
      final p = vm?.trigger(t);
      if (p != null) {
        p.trigger();
      } else {
        sm.trigger(t)?.fire();
      }
    }
  }

  @override
  void didUpdateWidget(RiveCharacter old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_push);
      widget.controller.addListener(_push);
    }
    _push();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_push);
    // Dispose in reverse order of creation (Rive docs).
    _vm?.dispose();
    _rc?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc = _rc;
    if (_failed || rc == null) return widget.fallback;
    return rive.RiveWidget(controller: rc, fit: rive.Fit.contain);
  }
}
