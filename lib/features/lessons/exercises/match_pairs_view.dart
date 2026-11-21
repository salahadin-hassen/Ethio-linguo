import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/components/shake.dart';
import '../../../data/models/exercise.dart';
import '../logic/answer_validator.dart';
import '../widgets/answer_tile.dart';

/// Tap a native word and its English meaning to match them. Wrong pairs
/// flash and shake but never cost hearts — matching is exploratory.
/// Calls [onCompleted] with the number of wrong attempts once all pairs match.
class MatchPairsView extends StatefulWidget {
  const MatchPairsView({
    super.key,
    required this.exercise,
    required this.onCompleted,
    required this.locked,
  });

  final MatchPairsExercise exercise;
  final ValueChanged<int> onCompleted;
  final bool locked;

  @override
  State<MatchPairsView> createState() => _MatchPairsViewState();
}

class _MatchPairsViewState extends State<MatchPairsView> {
  int? _left;
  int? _right; // index into pairs (not display order)
  final Set<int> _matched = {};
  (int, int)? _wrong;
  int _wrongCount = 0;
  int _shake = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tapLeft(int i) {
    setState(() => _left = _left == i ? null : i);
    _resolve();
  }

  void _tapRight(int pairIndex) {
    setState(() => _right = _right == pairIndex ? null : pairIndex);
    _resolve();
  }

  void _resolve() {
    final l = _left, r = _right;
    if (l == null || r == null) return;
    if (AnswerValidator.isMatch(widget.exercise, l, r)) {
      setState(() {
        _matched.add(l);
        _left = _right = null;
      });
      if (_matched.length == widget.exercise.pairs.length) {
        widget.onCompleted(_wrongCount);
      }
    } else {
      setState(() {
        _wrong = (l, r);
        _wrongCount++;
        _shake++;
        _left = _right = null;
      });
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 550), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  TileTone _tone(bool matched, bool selected, bool wrong) => matched
      ? TileTone.correct
      : wrong
      ? TileTone.wrong
      : selected
      ? TileTone.selected
      : TileTone.idle;

  @override
  Widget build(BuildContext context) {
    final pairs = widget.exercise.pairs;
    final busy = widget.locked;
    Widget cell(Widget child) =>
        Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < pairs.length; i++)
                cell(
                  Shake(
                    trigger: _wrong?.$1 == i ? _shake : 0,
                    child: AnswerTile(
                      key: ValueKey('match_left_$i'),
                      label: pairs[i].native,
                      tone: _tone(
                        _matched.contains(i),
                        _left == i,
                        _wrong?.$1 == i,
                      ),
                      onTap: busy || _matched.contains(i)
                          ? null
                          : () => _tapLeft(i),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              for (final p in widget.exercise.rightOrder)
                cell(
                  Shake(
                    trigger: _wrong?.$2 == p ? _shake : 0,
                    child: AnswerTile(
                      key: ValueKey('match_right_$p'),
                      label: pairs[p].english,
                      tone: _tone(
                        _matched.contains(p),
                        _right == p,
                        _wrong?.$2 == p,
                      ),
                      onTap: busy || _matched.contains(p)
                          ? null
                          : () => _tapRight(p),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
