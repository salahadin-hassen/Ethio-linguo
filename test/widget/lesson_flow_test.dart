import 'package:ethio_linguo/core/navigation/app_routes.dart';
import 'package:ethio_linguo/app/app_controller.dart';
import 'package:ethio_linguo/data/models/course.dart';
import 'package:ethio_linguo/data/models/exercise.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/features/home/home_shell.dart';
import 'package:ethio_linguo/features/lessons/lesson_complete_screen.dart';
import 'package:ethio_linguo/features/lessons/lesson_screen.dart';
import 'package:ethio_linguo/features/lessons/logic/lesson_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import '../helpers/lesson_driver.dart';

Future<void> openCurrentLesson(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('continue_learning')));
  await t.pumpAndSettle();
  expect(find.byType(LessonScreen), findsOneWidget);
}

void main() {
  testWidgets('check is disabled until an answer is chosen', (t) async {
    await pumpApp(t, progress: onboarded());
    await openCurrentLesson(t);
    await t.tap(find.byKey(const ValueKey('check_button')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('feedback_panel')), findsNothing);
  });

  testWidgets(
    'correct answer: teal feedback, progress advances, no heart lost',
    (t) async {
      final h = await pumpApp(t, progress: onboarded());
      await openCurrentLesson(t);
      final exs = lessonExercises('l_greetings', NativeLanguage.amharic);
      await answer(t, exs[0]);
      expect(find.textContaining('Nice work!'), findsOneWidget);
      expect(find.textContaining('ጎበዝ'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(h.controller.progress.hearts, 5);
      // Options are locked once checked.
      await t.tap(find.byKey(const ValueKey('option_0')));
      await t.pumpAndSettle();
      expect(find.textContaining('Nice work!'), findsOneWidget);
    },
  );

  testWidgets(
    'incorrect answer: encouraging feedback, solution shown, heart persisted',
    (t) async {
      final h = await pumpApp(t, progress: onboarded());
      await openCurrentLesson(t);
      final exs = lessonExercises('l_greetings', NativeLanguage.amharic);
      await answer(t, exs[0], correct: false);
      expect(find.textContaining("Not quite"), findsOneWidget);
      expect(
        find.text('Correct answer: ${exs[0].solutionText}'),
        findsOneWidget,
      );
      expect(find.text('−1 heart'), findsOneWidget);
      expect(find.text("You'll see this again"), findsOneWidget);
      expect(find.text('GOT IT'), findsOneWidget);
      await t.pump();
      expect(
        h.controller.progress.hearts,
        4,
        reason: 'heart loss saved immediately',
      );
      expect(h.store.value!.hearts, 4);
    },
  );

  testWidgets('typed answer with a small typo is accepted as "almost"', (
    t,
  ) async {
    await pumpApp(t, progress: onboarded());
    await openCurrentLesson(t);
    final exs = lessonExercises('l_greetings', NativeLanguage.amharic);
    await answer(t, exs[0]);
    await pressContinue(t);
    await answer(t, exs[1]);
    await pressContinue(t);
    expect(exs[2], isA<TypeAnswerExercise>());
    await t.enterText(
      find.byKey(const ValueKey('type_answer_field')),
      'Freind',
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('check_button')));
    await t.pumpAndSettle();
    expect(find.text('Almost! Check the spelling'), findsOneWidget);
    expect(find.text('Correct spelling: friend'), findsOneWidget);
  });

  testWidgets('sentence builder: tiles can be placed and removed', (t) async {
    await pumpApp(t, progress: onboarded());
    await openCurrentLesson(t);
    final exs = lessonExercises('l_greetings', NativeLanguage.amharic);
    for (var i = 0; i < 4; i++) {
      await answer(t, exs[i]);
      await pressContinue(t);
    }
    final s = exs[4] as BuildSentenceExercise;
    final hello = s.tiles.indexOf('Hello');
    await t.tap(find.byKey(ValueKey('bank_$hello')));
    await t.pumpAndSettle();
    expect(find.byKey(ValueKey('placed_$hello')), findsOneWidget);
    await t.tap(find.byKey(ValueKey('placed_$hello')));
    await t.pumpAndSettle();
    expect(find.byKey(ValueKey('placed_$hello')), findsNothing);
    expect(find.byKey(ValueKey('bank_$hello')), findsOneWidget);
  });

  testWidgets('match pairs: wrong pair does not complete, right pairs do', (
    t,
  ) async {
    await pumpApp(t, progress: onboarded());
    await openCurrentLesson(t);
    final exs = lessonExercises('l_greetings', NativeLanguage.amharic);
    for (var i = 0; i < 3; i++) {
      await answer(t, exs[i]);
      await pressContinue(t);
    }
    expect(exs[3], isA<MatchPairsExercise>());
    await t.tap(find.byKey(const ValueKey('match_left_0')));
    await t.tap(find.byKey(const ValueKey('match_right_1')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('feedback_panel')), findsNothing);
    await answer(t, exs[3]);
    expect(find.byKey(const ValueKey('feedback_panel')), findsOneWidget);
  });

  testWidgets(
    'full perfect lesson → completion screen → XP + path + garden updated',
    (t) async {
      final h = await pumpApp(t, progress: onboarded());
      await openCurrentLesson(t);
      final exs = lessonExercises('l_greetings', NativeLanguage.amharic);
      await playLesson(t, exs);
      expect(find.byType(LessonCompleteScreen), findsOneWidget);
      expect(find.text('Flawless lesson!'), findsOneWidget);
      final xp = AppController.xpFor(
        LessonResult(
          nodeId: 'n_greetings',
          totalExercises: exs.length,
          correctFirstTry: exs.length,
          mistakes: 0,
          heartsLeft: 5,
          correctTermIds: const {},
          missedTermIds: const {},
          bestRun: exs.length,
        ),
        NodeKind.lesson,
      );
      expect(xp, 10 + exs.length + 5);
      expect(h.controller.progress.totalXp, xp);
      expect(find.text('+$xp'), findsOneWidget);
      expect(
        find.text('${exs.length} of ${exs.length} correct on the first try'),
        findsOneWidget,
      );
      expect(find.textContaining('new words planted'), findsOneWidget);
      expect(find.text('Badge unlocked: First Steps'), findsOneWidget);
      expect(h.store.value!.completedNodeIds, contains('n_greetings'));
      expect(h.store.value!.streak, 1);
      expect(
        h.store.value!.words.keys,
        containsAll(['hello', 'thank_you', 'yes', 'no', 'friend']),
      );

      await t.tap(find.byKey(const ValueKey('complete_continue')));
      await t.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.bySemanticsLabel('$xp XP'), findsOneWidget);
      expect(find.bySemanticsLabel('1 day streak'), findsOneWidget);
      expect(
        find.text('Coffee time'),
        findsWidgets,
        reason: 'next lesson unlocked',
      );
    },
  );

  testWidgets(
    'lesson with mistakes still completes; mistakes retried at the end',
    (t) async {
      final h = await pumpApp(t, progress: onboarded());
      await openCurrentLesson(t);
      final exs = lessonExercises('l_greetings', NativeLanguage.amharic);
      await playLesson(t, exs, wrongAt: {0, 2});
      expect(find.text('Lesson complete!'), findsOneWidget);
      expect(
        find.text(
          '${exs.length - 2} of ${exs.length} correct on the first try',
        ),
        findsOneWidget,
      );
      expect(h.controller.progress.hearts, 3);
      expect(h.controller.progress.perfectNodeIds, isEmpty);
    },
  );

  testWidgets('Afaan Oromo learners get Oromo prompts and instructions', (
    t,
  ) async {
    await pumpApp(t, progress: onboarded(native: NativeLanguage.oromo));
    await openCurrentLesson(t);
    expect(find.text('Akkam'), findsOneWidget);
    expect(find.text('Kun maal jechuudha?'), findsOneWidget);
    final exs = lessonExercises('l_greetings', NativeLanguage.oromo);
    await playLesson(t, exs);
    expect(find.byType(LessonCompleteScreen), findsOneWidget);
  });

  testWidgets('quitting asks for confirmation and returns home', (t) async {
    await pumpApp(t, progress: onboarded());
    await openCurrentLesson(t);
    await t.tap(find.byKey(const ValueKey('close_lesson')));
    await t.pumpAndSettle();
    expect(find.text('Leave this lesson?'), findsOneWidget);
    await t.tap(find.text('KEEP LEARNING'));
    await t.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('close_lesson')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('confirm_quit')));
    await t.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('word garden watering session plays and awards XP', (t) async {
    final h = await pumpApp(t, progress: midJourney());
    await openRoute(t, AppRoutes.garden);
    await t.tap(find.byKey(const ValueKey('water_garden')));
    await t.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
    // Answer whatever appears until the completion screen.
    for (
      var guard = 0;
      guard < 30 && find.byType(LessonCompleteScreen).evaluate().isEmpty;
      guard++
    ) {
      if (find.byKey(const ValueKey('match_left_0')).evaluate().isNotEmpty &&
          find.byKey(const ValueKey('feedback_panel')).evaluate().isEmpty) {
        // Unknown pair order: brute-force matching (wrong pairs are free).
        for (var l = 0; l < 4; l++) {
          for (var r = 0; r < 4; r++) {
            final done = find.byKey(const ValueKey('feedback_panel'));
            if (done.evaluate().isNotEmpty) {
              break;
            }
            final left = find.byKey(ValueKey('match_left_$l'));
            final right = find.byKey(ValueKey('match_right_$r'));
            if (left.evaluate().isEmpty || right.evaluate().isEmpty) {
              continue;
            }
            await t.tap(left);
            await t.tap(right);
            await t.pumpAndSettle();
          }
        }
      } else if (find.byKey(const ValueKey('option_0')).evaluate().isNotEmpty &&
          find.byKey(const ValueKey('feedback_panel')).evaluate().isEmpty) {
        await t.tap(find.byKey(const ValueKey('option_0')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('check_button')));
        await t.pumpAndSettle();
      } else if (find
              .byKey(const ValueKey('type_answer_field'))
              .evaluate()
              .isNotEmpty &&
          find.byKey(const ValueKey('feedback_panel')).evaluate().isEmpty) {
        await t.enterText(
          find.byKey(const ValueKey('type_answer_field')),
          'hello',
        );
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('check_button')));
        await t.pumpAndSettle();
      }
      if (find.byKey(const ValueKey('continue_button')).evaluate().isNotEmpty) {
        await pressContinue(t);
      }
    }
    expect(find.byType(LessonCompleteScreen), findsOneWidget);
    expect(h.controller.progress.totalXp, greaterThan(58));
  });
}
