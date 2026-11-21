import 'package:ethio_linguo/app/app.dart';
import 'package:ethio_linguo/app/app_controller.dart';
import 'package:ethio_linguo/data/local/demo_course.dart';
import 'package:ethio_linguo/data/local/progress_store.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/data/models/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final fixedNow = DateTime(2026, 11, 20, 9, 30);
String get todayKey => dayKey(fixedNow);
String daysAgo(int n) => dayKey(fixedNow.subtract(Duration(days: n)));

class Harness {
  Harness(this.controller, this.store);
  final AppController controller;
  final InMemoryProgressStore store;
}

/// Pumps the full app with an in-memory store and a fixed clock.
/// [reducedMotion] makes looping animations stop so pumpAndSettle works.
Future<Harness> pumpApp(
  WidgetTester tester, {
  LearnerProgress? progress,
  bool reducedMotion = true,
  Size size = const Size(390, 844),
  double dpr = 2,
  DateTime Function()? clock,
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  if (reducedMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  final store = InMemoryProgressStore(progress);
  final controller = await AppController.load(
    course: DemoCourse.course,
    store: store,
    clock: clock ?? () => fixedNow,
  );
  await tester.pumpWidget(LearningApp(controller: controller));
  await tester.pump();
  if (reducedMotion) await tester.pumpAndSettle();
  return Harness(controller, store);
}

LearnerProgress onboarded({NativeLanguage native = NativeLanguage.amharic}) =>
    LearnerProgress(onboarded: true, native: native);

/// A learner a few days in: lesson 1 done, streak 3, some garden growth.
LearnerProgress midJourney({NativeLanguage native = NativeLanguage.amharic}) =>
    LearnerProgress(
      onboarded: true,
      native: native,
      totalXp: 58,
      streak: 3,
      lastActiveDay: daysAgo(1),
      hearts: 4,
      heartsDay: todayKey,
      completedNodeIds: const {'n_greetings'},
      perfectNodeIds: const {'n_greetings'},
      longestCorrectRun: 6,
      words: {
        'hello': WordProgress(strength: 3, lastPracticed: daysAgo(1)),
        'thank_you': WordProgress(strength: 2, lastPracticed: daysAgo(3)),
        'yes': WordProgress(strength: 1, lastPracticed: daysAgo(2)),
        'no': WordProgress(strength: 1, lastPracticed: daysAgo(1)),
        'friend': WordProgress(strength: 0, lastPracticed: daysAgo(1)),
      },
      daily: DailyStats(day: todayKey, xp: 12, lessons: 1),
    );
