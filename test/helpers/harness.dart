import 'dart:async';

import 'package:ethio_linguo/app/app.dart';
import 'package:ethio_linguo/app/app_services.dart';
import 'package:ethio_linguo/data/repositories/content_repository.dart';
import 'package:ethio_linguo/data/repositories/vocabulary_repository.dart';
import 'package:ethio_linguo/services/analytics/analytics.dart';
import 'package:ethio_linguo/services/playback/media_playback.dart';
import 'package:ethio_linguo/services/speech/speech_services.dart';
import 'package:ethio_linguo/services/tutor/tutor_engine.dart';
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
  Harness(this.controller, this.store, this.services);
  final AppController controller;
  final InMemoryProgressStore store;
  final AppServices services;
}

/// In-memory services with the REAL bundled content pre-loaded. Asset I/O is
/// real async work that cannot finish inside the widget-test fake clock, so
/// it is done up front with runAsync; repositories cache the results.
Future<AppServices> warmServices(
  WidgetTester tester, {
  VocabularyRepository? vocabulary,
  TutorEngine? tutor,
  SpeechRecognizer? speechIn,
  SpeechSynthesizer? speechOut,
  RecordingAnalytics? analytics,
  MediaPlaybackFactory? playbackFactory,
}) async {
  final content = BundledContentRepository();
  final transcripts = BundledTranscriptRepository();
  await tester.runAsync(() async {
    final all = await content.list();
    for (final c in all) {
      await transcripts.load(
        c,
        languages: [for (final l in NativeLanguage.values) l.code],
      );
    }
  });
  return AppServices.inMemory(
    content: content,
    transcripts: transcripts,
    vocabulary: vocabulary,
    tutor: tutor,
    speechIn: speechIn,
    speechOut: speechOut,
    analytics: analytics,
    playbackFactory: playbackFactory,
  );
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
  AppServices? services,
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
  services ??= await warmServices(tester);
  final controller = await AppController.load(
    course: DemoCourse.course,
    store: store,
    clock: clock ?? () => fixedNow,
  );
  await tester.pumpWidget(
    LearningApp(controller: controller, services: services),
  );
  await tester.pump();
  if (reducedMotion) await tester.pumpAndSettle();
  return Harness(controller, store, services);
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

/// Pushes a named route on the app's root navigator (for routes that are no
/// longer bottom tabs, e.g. the Word Garden and Badges).
Future<void> openRoute(
  WidgetTester t,
  String route, {
  Object? arguments,
}) async {
  final nav = t.state<NavigatorState>(find.byType(Navigator).first);
  unawaited(nav.pushNamed(route, arguments: arguments));
  await t.pumpAndSettle();
}

Future<void> tapTab(WidgetTester t, String label) async {
  await t.tap(find.byKey(ValueKey('nav_$label')));
  await t.pumpAndSettle();
}
