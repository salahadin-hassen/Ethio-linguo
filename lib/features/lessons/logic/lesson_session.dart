import 'package:flutter/foundation.dart';

import '../../../data/models/exercise.dart';
import 'answer_validator.dart';

enum SessionPhase { answering, feedback, finished }

/// Outcome of one lesson, handed to the app controller for rewards.
class LessonResult {
  const LessonResult({
    required this.nodeId,
    required this.totalExercises,
    required this.correctFirstTry,
    required this.mistakes,
    required this.heartsLeft,
    required this.correctTermIds,
    required this.missedTermIds,
    required this.bestRun,
  });

  final String nodeId;
  final int totalExercises;
  final int correctFirstTry;
  final int mistakes;
  final int heartsLeft;
  final Set<String> correctTermIds;
  final Set<String> missedTermIds;
  final int bestRun;

  bool get perfect => mistakes == 0;
  double get accuracy =>
      totalExercises == 0 ? 1 : correctFirstTry / totalExercises;
}

/// Pure lesson state machine (no widgets). Beginner-friendly rules:
/// - a mistake costs one heart and the exercise is retried once at the end;
/// - when hearts run out the lesson continues in practice mode instead of
///   ending — learners are never locked out mid-lesson.
class LessonSession extends ChangeNotifier {
  LessonSession({
    required this.nodeId,
    required List<Exercise> exercises,
    required this._hearts,
    this.onHeartLost,
  }) : assert(exercises.isNotEmpty),
       _queue = List.of(exercises),
       total = exercises.length;

  final String nodeId;
  final int total;
  final void Function(int heartsLeft)? onHeartLost;

  final List<Exercise> _queue;
  final Set<String> _solved = {};
  final Set<String> _retried = {};
  final Set<String> _missedOnce = {};
  final Set<String> _correctTerms = {};
  final Set<String> _missedTerms = {};
  int _index = 0;
  int _hearts;
  int _mistakes = 0;
  int _run = 0;
  int _bestRun = 0;
  SessionPhase _phase = SessionPhase.answering;
  Verdict? _lastVerdict;

  Exercise get current => _queue[_index];
  int get hearts => _hearts;
  int get mistakes => _mistakes;
  int get streakRun => _run;
  SessionPhase get phase => _phase;
  Verdict? get lastVerdict => _lastVerdict;
  bool get practiceMode => _hearts <= 0;
  bool get isRetry => _index >= total;
  double get progress => _solved.length / total;

  /// Records the learner's verdict for the current exercise.
  void submit(Verdict verdict) {
    if (_phase != SessionPhase.answering) return;
    final ex = current;
    _lastVerdict = verdict;
    if (verdict == Verdict.incorrect) {
      _mistakes++;
      _run = 0;
      _missedOnce.add(ex.id);
      _missedTerms.addAll(ex.termIds);
      if (_hearts > 0) {
        _hearts--;
        onHeartLost?.call(_hearts);
      }
      if (_retried.add(ex.id)) {
        _queue.add(ex); // one more chance at the end
      } else {
        _solved.add(ex.id); // don't loop forever; move on
      }
    } else {
      _solved.add(ex.id);
      _run++;
      if (_run > _bestRun) _bestRun = _run;
      if (!_missedOnce.contains(ex.id)) _correctTerms.addAll(ex.termIds);
    }
    _phase = SessionPhase.feedback;
    notifyListeners();
  }

  void next() {
    if (_phase != SessionPhase.feedback) return;
    _index++;
    _lastVerdict = null;
    _phase = _index >= _queue.length
        ? SessionPhase.finished
        : SessionPhase.answering;
    notifyListeners();
  }

  LessonResult result() => LessonResult(
    nodeId: nodeId,
    totalExercises: total,
    correctFirstTry: total - _missedOnce.length,
    mistakes: _mistakes,
    heartsLeft: _hearts,
    correctTermIds: _correctTerms.difference(_missedTerms),
    missedTermIds: _missedTerms,
    bestRun: _bestRun,
  );
}
