import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/features/lessons/lesson_complete_screen.dart';
import 'package:ethio_linguo/features/mascot/mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import '../helpers/lesson_driver.dart';

void main() {
  testWidgets('with animations ON: screens animate without errors', (t) async {
    await pumpApp(t, progress: midJourney(), reducedMotion: false);
    // Idle mascot + pulsing node keep animating; pump real frames.
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(
      t.binding.hasScheduledFrame,
      isTrue,
      reason: 'idle animation is running',
    );
    await t.tap(find.byKey(const ValueKey('nav_Learn')));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('with reduced motion: nothing loops (UI fully settles)', (
    t,
  ) async {
    await pumpApp(t, progress: midJourney());
    // pumpAndSettle would time out if any animation looped forever.
    await t.pumpAndSettle();
    expect(t.binding.hasScheduledFrame, isFalse);
    await t.tap(find.byKey(const ValueKey('nav_Learn')));
    await t.pumpAndSettle();
    expect(t.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('completion celebration runs and then stops', (t) async {
    await pumpApp(t, progress: onboarded());
    await t.tap(find.byKey(const ValueKey('continue_learning')));
    await t.pumpAndSettle();
    await playLesson(t, lessonExercises('l_greetings', NativeLanguage.amharic));
    expect(find.byType(LessonCompleteScreen), findsOneWidget);
    expect(find.byType(Mascot), findsWidgets);
  });

  testWidgets('mascot renders every expression at several sizes', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final m in MascotMood.values)
              for (final s in [24.0, 64.0, 160.0])
                Mascot(mood: m, size: s, animate: false),
          ],
        ),
      ),
    );
    expect(find.byType(Mascot), findsNWidgets(MascotMood.values.length * 3));
    expect(t.takeException(), isNull);
  });
}
