// Renders every screen at phone size with the real bundled fonts.
// Run: flutter test test/screenshots --update-goldens
// Output: test/screenshots/out/*.png (copied to docs/screenshots).
@Tags(['screenshots'])
library;

import 'package:ethio_linguo/core/navigation/app_routes.dart';

import 'package:ethio_linguo/app/app.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fonts.dart';
import '../helpers/harness.dart';
import '../helpers/lesson_driver.dart';

Future<void> shot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$name.png'));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('01 welcome', (t) async {
    await pumpApp(t);
    await shot(t, '01_welcome');
  });

  testWidgets('02 language selection', (t) async {
    await pumpApp(t);
    await t.tap(find.text('GET STARTED'));
    await t.pumpAndSettle();
    await t.tap(find.text('አማርኛ'));
    await t.pumpAndSettle();
    await shot(t, '02_language_selection');
  });

  testWidgets('03 home fresh', (t) async {
    await pumpApp(t, progress: onboarded());
    await shot(t, '03_home_new_learner');
  });

  testWidgets('04 home mid journey', (t) async {
    await pumpApp(t, progress: midJourney());
    await shot(t, '04_home_progress');
    await t.drag(find.byType(CustomScrollView).first, const Offset(0, -600));
    await t.pumpAndSettle();
    await shot(t, '05_home_scrolled');
  });

  testWidgets('06 learning path', (t) async {
    await pumpApp(t, progress: midJourney());
    await t.tap(find.byKey(const ValueKey('nav_Learn')));
    await t.pumpAndSettle();
    await shot(t, '06_learning_path');
  });

  testWidgets('07 lesson flow', (t) async {
    await pumpApp(t, progress: midJourney());
    await t.tap(find.byKey(const ValueKey('continue_learning')));
    await t.pumpAndSettle();
    await shot(t, '07_lesson_multiple_choice');
    // Pick correct answer ("coffee").
    await t.tap(find.text('coffee'));
    await t.pumpAndSettle();
    await shot(t, '08_lesson_selected');
    await t.tap(find.byKey(const ValueKey('check_button')));
    await t.pumpAndSettle();
    await shot(t, '09_lesson_correct');
    await t.tap(find.byKey(const ValueKey('continue_button')));
    await t.pumpAndSettle();
    // Exercise 2: choose translation of "water" — answer wrong on purpose.
    await t.tap(find.text('ወተት'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('check_button')));
    await t.pumpAndSettle();
    await shot(t, '10_lesson_incorrect');
    await t.tap(find.byKey(const ValueKey('continue_button')));
    await t.pumpAndSettle();
    await shot(t, '11_lesson_match_pairs');
    await t.tap(find.byKey(const ValueKey('match_left_0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('match_right_0')));
    await t.tap(find.byKey(const ValueKey('match_left_1')));
    await t.pumpAndSettle();
    await shot(t, '12_lesson_match_progress');
  });

  testWidgets('13 lesson type + sentence', (t) async {
    await pumpApp(t, progress: onboarded());
    await t.tap(find.byKey(const ValueKey('continue_learning')));
    await t.pumpAndSettle();
    // Greetings lesson: ex0 MC hello, ex1 MC thank you, ex2 type friend.
    await t.tap(find.text('hello'));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('check_button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('continue_button')));
    await t.pumpAndSettle();
    await t.tap(find.text('አመሰግናለሁ'));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('check_button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('continue_button')));
    await t.pumpAndSettle();
    await t.enterText(
      find.byKey(const ValueKey('type_answer_field')),
      'freind',
    );
    await t.pumpAndSettle();
    await shot(t, '13_lesson_type_answer');
    await t.tap(find.byKey(const ValueKey('check_button')));
    await t.pumpAndSettle();
    await shot(t, '14_lesson_almost');
    await t.tap(find.byKey(const ValueKey('continue_button')));
    await t.pumpAndSettle();
    // Match pairs: complete it.
    for (var i = 0; i < 4; i++) {
      await t.tap(find.byKey(ValueKey('match_left_$i')));
      await t.tap(find.byKey(ValueKey('match_right_$i')));
      await t.pumpAndSettle();
    }
    await t.tap(find.byKey(const ValueKey('continue_button')));
    await t.pumpAndSettle();
    // Build sentence: Hello my friend — tap two tiles.
    await t.tap(find.text('Hello'));
    await t.tap(find.text('my'));
    await t.pumpAndSettle();
    await shot(t, '15_lesson_build_sentence');
  });

  testWidgets('16 completion', (t) async {
    await pumpApp(t, progress: midJourney());
    await t.tap(find.byKey(const ValueKey('continue_learning')));
    await t.pumpAndSettle();
    await playLesson(t, lessonExercises('l_coffee', NativeLanguage.amharic));
    // Re-enable motion so the confetti burst is visible mid-flight.
    t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await t.pumpWidget(t.widget(find.byType(LearningApp)));
    await t.pump(const Duration(milliseconds: 500));
    await shot(t, '16_lesson_complete');
  });

  testWidgets('17 word garden + badges', (t) async {
    await pumpApp(t, progress: midJourney());
    await openRoute(t, AppRoutes.garden);
    await shot(t, '17_word_garden');
    await openRoute(t, AppRoutes.achievements);
    await shot(t, '18_badges');
  });

  testWidgets('19 garden empty', (t) async {
    await pumpApp(t, progress: onboarded());
    await openRoute(t, AppRoutes.garden);
    await shot(t, '19_word_garden_empty');
  });

  testWidgets('20 oromo home', (t) async {
    await pumpApp(t, progress: midJourney(native: NativeLanguage.oromo));
    await shot(t, '20_home_afaan_oromo');
    await t.tap(find.byKey(const ValueKey('continue_learning')));
    await t.pumpAndSettle();
    await shot(t, '21_lesson_afaan_oromo');
  });
}
