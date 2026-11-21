import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models/course.dart';
import '../data/models/gamification.dart';
import '../data/models/language.dart';
import '../data/models/progress.dart';
import '../data/local/progress_store.dart';
import '../features/lessons/logic/lesson_session.dart';

enum NodeState { completed, current, locked }

/// What a finished lesson earned — drives the completion screen.
class LessonReward {
  const LessonReward({
    required this.result,
    required this.xpEarned,
    required this.levelBefore,
    required this.levelAfter,
    required this.streakBefore,
    required this.streakAfter,
    required this.plantedWords,
    required this.grownWords,
    required this.newAchievements,
    required this.unitProgressBefore,
    required this.unitProgressAfter,
  });

  final LessonResult result;
  final int xpEarned;
  final LevelInfo levelBefore;
  final LevelInfo levelAfter;
  final int streakBefore;
  final int streakAfter;
  final List<String> plantedWords;
  final List<String> grownWords;
  final List<Achievement> newAchievements;
  final double unitProgressBefore;
  final double unitProgressAfter;

  bool get leveledUp => levelAfter.level > levelBefore.level;
  bool get streakExtended => streakAfter > streakBefore;
}

/// Single source of truth for learner state. Owns persistence and all
/// gamification rules so screens stay presentational.
class AppController extends ChangeNotifier {
  AppController({
    required this.course,
    required this._store,
    LearnerProgress? initial,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _progress = initial ?? const LearnerProgress() {
    _refreshForToday();
  }

  final Course course;
  final ProgressStore _store;
  final DateTime Function() _clock;
  LearnerProgress _progress;

  LearnerProgress get progress => _progress;
  DateTime get now => _clock();
  String get today => dayKey(_clock());
  NativeLanguage get native => _progress.native ?? NativeLanguage.amharic;
  LevelInfo get level => LevelInfo.fromXp(_progress.totalXp);
  int get streak => _progress.streakOn(today);
  bool get practicedToday => _progress.activeOn(today);
  List<DailyQuest> get quests => DailyQuest.forDay(_progress.dailyFor(today));

  Set<String> get _checkpointIds => {
    for (final n in course.allNodes)
      if (n.kind == NodeKind.checkpoint) n.id,
  };

  List<Achievement> get achievements =>
      Achievement.evaluate(_progress, checkpointIds: _checkpointIds);

  /// Loads persisted progress. Safe to call once at startup.
  static Future<AppController> load({
    required Course course,
    required ProgressStore store,
    DateTime Function()? clock,
  }) async {
    final saved = await store.load();
    return AppController(
      course: course,
      store: store,
      initial: saved,
      clock: clock,
    );
  }

  void _refreshForToday() {
    if (_progress.heartsDay != today) {
      _progress = _progress.copyWith(
        hearts: LearnerProgress.maxHearts,
        heartsDay: today,
      );
    }
  }

  Future<void> _commit(LearnerProgress next) async {
    _progress = next;
    notifyListeners();
    await _store.save(next);
  }

  Future<void> chooseLanguages(NativeLanguage native, TargetLanguage target) =>
      _commit(
        _progress.copyWith(native: native, target: target, onboarded: true),
      );

  Future<void> setHearts(int hearts) => _commit(
    _progress.copyWith(hearts: hearts.clamp(0, LearnerProgress.maxHearts)),
  );

  Future<void> resetProgress() async {
    await _store.clear();
    _progress = const LearnerProgress();
    _refreshForToday();
    notifyListeners();
  }

  // ---------- Learning path ----------

  NodeState stateOf(PathNode node) {
    if (_progress.completedNodeIds.contains(node.id)) {
      return NodeState.completed;
    }
    return currentNode?.id == node.id ? NodeState.current : NodeState.locked;
  }

  /// First node (in path order) not yet completed.
  PathNode? get currentNode {
    for (final n in course.allNodes) {
      if (!_progress.completedNodeIds.contains(n.id)) return n;
    }
    return null;
  }

  double unitProgress(Unit unit, [LearnerProgress? p]) {
    final done = unit.nodes
        .where((n) => (p ?? _progress).completedNodeIds.contains(n.id))
        .length;
    return done / unit.nodes.length;
  }

  // ---------- Word garden ----------

  List<String> get wordsNeedingWater => [
    for (final e in _progress.words.entries)
      if (e.value.needsWater(today)) e.key,
  ];

  /// Words for a watering session: thirsty first, then weakest.
  List<String> wordsForReview({int max = 6}) {
    final entries = _progress.words.entries.toList()
      ..sort((a, b) {
        final wa = a.value.needsWater(today) ? 0 : 1;
        final wb = b.value.needsWater(today) ? 0 : 1;
        if (wa != wb) return wa - wb;
        return a.value.strength - b.value.strength;
      });
    return entries.take(max).map((e) => e.key).toList();
  }

  // ---------- Rewards ----------

  static int xpFor(LessonResult r, NodeKind kind) {
    final base = switch (kind) {
      NodeKind.lesson => 10,
      NodeKind.practice => 5,
      NodeKind.checkpoint => 15,
    };
    return base + r.correctFirstTry + (r.perfect ? 5 : 0);
  }

  Future<LessonReward> completeLesson(
    LessonResult r, {
    NodeKind? kindOverride,
  }) async {
    final p = _progress;
    final node = course.nodeById(r.nodeId);
    final kind = kindOverride ?? node?.kind ?? NodeKind.practice;
    final xp = xpFor(r, kind);
    final t = today;

    // Streak: consecutive active days.
    final streakBefore = p.streakOn(t);
    final int newStreak;
    if (p.lastActiveDay == t) {
      newStreak = max(p.streak, 1);
    } else if (p.lastActiveDay != null &&
        daysBetween(p.lastActiveDay!, t) == 1) {
      newStreak = p.streak + 1;
    } else {
      newStreak = 1;
    }

    // Word garden: plant new words, grow practised ones, wilt missed ones.
    final words = Map<String, WordProgress>.of(p.words);
    final planted = <String>[];
    final grown = <String>[];
    final lesson = node?.lessonId == null
        ? null
        : course.lessons[node!.lessonId];
    for (final id in lesson?.newTermIds ?? const <String>[]) {
      if (!words.containsKey(id)) {
        words[id] = WordProgress(strength: 0, lastPracticed: t);
        planted.add(id);
      }
    }
    for (final id in r.correctTermIds) {
      final w = words[id];
      if (w == null) continue;
      if (planted.contains(id) && w.strength == 0) {
        words[id] = w.copyWith(strength: 1, lastPracticed: t);
        continue;
      }
      if (w.strength < WordProgress.maxStrength) grown.add(id);
      words[id] = w.copyWith(
        strength: min(w.strength + 1, WordProgress.maxStrength),
        lastPracticed: t,
      );
    }
    for (final id in r.missedTermIds) {
      final w = words[id];
      if (w != null) {
        words[id] = w.copyWith(
          strength: max(w.strength - 1, 0),
          lastPracticed: t,
        );
      }
    }

    final daily = p.dailyFor(t);
    final completed = {...p.completedNodeIds};
    if (node != null) completed.add(node.id);
    final perfect = {...p.perfectNodeIds};
    if (r.perfect && node != null) perfect.add(node.id);

    final unit = node == null ? null : course.unitOf(node.id);
    final before = achievements
        .where((a) => a.unlocked)
        .map((a) => a.id)
        .toSet();
    final next = p.copyWith(
      totalXp: p.totalXp + xp,
      streak: newStreak,
      lastActiveDay: t,
      hearts: r.heartsLeft,
      completedNodeIds: completed,
      perfectNodeIds: perfect,
      words: words,
      daily: DailyStats(
        day: t,
        xp: daily.xp + xp,
        lessons: daily.lessons + 1,
        perfectLessons: daily.perfectLessons + (r.perfect ? 1 : 0),
      ),
      longestCorrectRun: max(p.longestCorrectRun, r.bestRun),
    );
    final reward = LessonReward(
      result: r,
      xpEarned: xp,
      levelBefore: LevelInfo.fromXp(p.totalXp),
      levelAfter: LevelInfo.fromXp(next.totalXp),
      streakBefore: streakBefore,
      streakAfter: newStreak,
      plantedWords: planted,
      grownWords: grown,
      newAchievements: Achievement.evaluate(
        next,
        checkpointIds: _checkpointIds,
      ).where((a) => a.unlocked && !before.contains(a.id)).toList(),
      unitProgressBefore: unit == null ? 0 : unitProgress(unit, p),
      unitProgressAfter: unit == null ? 0 : unitProgress(unit, next),
    );
    await _commit(next);
    return reward;
  }
}
