import 'dart:convert';

import 'package:ethio_linguo/app/app_controller.dart';
import 'package:ethio_linguo/data/local/demo_course.dart';
import 'package:ethio_linguo/data/local/progress_store.dart';
import 'package:ethio_linguo/data/models/course.dart';
import 'package:ethio_linguo/data/models/gamification.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/data/models/progress.dart';
import 'package:ethio_linguo/features/lessons/logic/lesson_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LessonResult result(
  String node, {
  int total = 7,
  int mistakes = 0,
  Set<String> correct = const {},
  Set<String> missed = const {},
  int hearts = 5,
}) => LessonResult(
  nodeId: node,
  totalExercises: total,
  correctFirstTry: total - mistakes,
  mistakes: mistakes,
  heartsLeft: hearts,
  correctTermIds: correct,
  missedTermIds: missed,
  bestRun: total - mistakes,
);

void main() {
  var now = DateTime(2026, 11, 20, 10);
  AppController make([LearnerProgress? p, InMemoryProgressStore? store]) =>
      AppController(
        course: DemoCourse.course,
        store: store ?? InMemoryProgressStore(),
        initial:
            p ??
            const LearnerProgress(
              onboarded: true,
              native: NativeLanguage.amharic,
            ),
        clock: () => now,
      );
  setUp(() => now = DateTime(2026, 11, 20, 10));

  test('initial path state: first node current, rest locked', () {
    final c = make();
    final nodes = DemoCourse.course.allNodes;
    expect(c.stateOf(nodes[0]), NodeState.current);
    expect(nodes.skip(1).map(c.stateOf).toSet(), {NodeState.locked});
  });

  test(
    'perfect lesson: XP, streak, completion, garden, quests, badges',
    () async {
      final store = InMemoryProgressStore();
      final c = make(null, store);
      final reward = await c.completeLesson(
        result('n_greetings', correct: {'hello', 'friend'}),
      );
      expect(reward.xpEarned, 10 + 7 + 5);
      expect(c.progress.totalXp, 22);
      expect(reward.streakBefore, 0);
      expect(reward.streakAfter, 1);
      expect(
        c.stateOf(DemoCourse.course.nodeById('n_greetings')!),
        NodeState.completed,
      );
      expect(c.currentNode!.id, 'n_coffee');
      expect(
        reward.plantedWords,
        containsAll(['hello', 'thank_you', 'yes', 'no', 'friend']),
      );
      expect(
        c.progress.words['hello']!.strength,
        1,
        reason: 'answered correctly → sprout',
      );
      expect(
        c.progress.words['yes']!.strength,
        0,
        reason: 'only planted → seed',
      );
      expect(
        c.quests.firstWhere((q) => q.kind == QuestKind.perfectLesson).done,
        isTrue,
      );
      expect(
        reward.newAchievements.map((a) => a.id),
        containsAll([AchievementId.firstSteps, AchievementId.perfectionist]),
      );
      expect(reward.unitProgressBefore, 0);
      expect(reward.unitProgressAfter, 0.25);
      expect(store.value!.totalXp, 22, reason: 'persisted');
    },
  );

  test('mistakes reduce XP and wilt missed words', () async {
    final c = make(
      LearnerProgress(
        onboarded: true,
        native: NativeLanguage.amharic,
        words: {'water': WordProgress(strength: 2, lastPracticed: dayKey(now))},
      ),
    );
    final r = await c.completeLesson(
      result('n_greetings', mistakes: 2, missed: {'water'}, hearts: 3),
    );
    expect(r.xpEarned, 10 + 5);
    expect(c.progress.words['water']!.strength, 1);
    expect(c.progress.hearts, 3);
  });

  test('streak: consecutive days extend, gaps reset, same day keeps', () async {
    final c = make();
    await c.completeLesson(result('n_greetings'));
    expect(c.streak, 1);
    await c.completeLesson(result('n_coffee'));
    expect(c.streak, 1, reason: 'same day');
    now = now.add(const Duration(days: 1));
    final r = await c.completeLesson(result('n_u1_practice'));
    expect(r.streakAfter, 2);
    now = now.add(const Duration(days: 3));
    expect(c.streak, 0, reason: 'broken streak displays as 0');
    final r2 = await c.completeLesson(result('n_u1_check'));
    expect(r2.streakAfter, 1);
  });

  test('hearts refill on a new day', () async {
    final c = make(
      LearnerProgress(
        onboarded: true,
        hearts: 1,
        heartsDay: dayKey(now.subtract(const Duration(days: 1))),
      ),
    );
    expect(c.progress.hearts, LearnerProgress.maxHearts);
  });

  test('levels accumulate from XP', () {
    expect(LevelInfo.fromXp(0).level, 1);
    expect(LevelInfo.fromXp(39).level, 1);
    expect(LevelInfo.fromXp(40).level, 2);
    expect(LevelInfo.fromXp(40 + 70).level, 3);
  });

  test('word garden: needs-water and review ordering', () {
    final today = dayKey(now);
    final c = make(
      LearnerProgress(
        onboarded: true,
        words: {
          'hello': WordProgress(strength: 3, lastPracticed: today),
          'water': WordProgress(
            strength: 0,
            lastPracticed: dayKey(now.subtract(const Duration(days: 2))),
          ),
          'bread': WordProgress(strength: 1, lastPracticed: today),
        },
      ),
    );
    expect(c.wordsNeedingWater, ['water']);
    expect(c.wordsForReview().first, 'water');
    expect(c.progress.words['hello']!.stage, GrowthStage.bloom);
  });

  test(
    'garden review (no path node) awards practice XP without completing nodes',
    () async {
      final c = make();
      final r = await c.completeLesson(
        result('garden_review', total: 5),
        kindOverride: NodeKind.practice,
      );
      expect(r.xpEarned, 5 + 5 + 5);
      expect(c.progress.completedNodeIds, isEmpty);
    },
  );

  test('progress JSON round-trips', () {
    final p = LearnerProgress(
      onboarded: true,
      native: NativeLanguage.oromo,
      totalXp: 42,
      streak: 2,
      lastActiveDay: '2026-11-19',
      hearts: 3,
      completedNodeIds: const {'n_greetings'},
      words: const {
        'hello': WordProgress(strength: 2, lastPracticed: '2026-11-19'),
      },
      daily: const DailyStats(day: '2026-11-19', xp: 10, lessons: 1),
    );
    final back = LearnerProgress.fromJson(
      jsonDecode(jsonEncode(p.toJson())) as Map<String, Object?>,
    );
    expect(back.native, NativeLanguage.oromo);
    expect(back.totalXp, 42);
    expect(back.completedNodeIds, {'n_greetings'});
    expect(back.words['hello']!.strength, 2);
    expect(back.daily!.xp, 10);
  });

  group('SharedPrefsProgressStore', () {
    test('save then load', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await SharedPrefsProgressStore.create();
      await store.save(const LearnerProgress(onboarded: true, totalXp: 7));
      final loaded = await (await SharedPrefsProgressStore.create()).load();
      expect(loaded!.totalXp, 7);
    });

    test(
      'corrupt data falls back to a fresh start instead of crashing',
      () async {
        SharedPreferences.setMockInitialValues({
          'learner_progress_v1': '{not json',
        });
        final store = await SharedPrefsProgressStore.create();
        expect(await store.load(), isNull);
      },
    );

    test('reset clears storage', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await SharedPrefsProgressStore.create();
      final c = AppController(
        course: DemoCourse.course,
        store: store,
        initial: const LearnerProgress(onboarded: true, totalXp: 9),
      );
      await c.resetProgress();
      expect(await store.load(), isNull);
      expect(c.progress.onboarded, isFalse);
    });
  });
}
