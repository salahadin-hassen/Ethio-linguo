import 'package:ethio_linguo/data/local/demo_course.dart';
import 'package:ethio_linguo/data/models/exercise.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/features/lessons/logic/lesson_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Same deterministic build the LessonScreen performs.
List<Exercise> lessonExercises(String lessonId, NativeLanguage native) =>
    LessonBuilder(
      DemoCourse.course,
      native,
    ).buildLesson(DemoCourse.lessons[lessonId]!);

Future<void> _tapKey(WidgetTester t, String key) async {
  await t.ensureVisible(find.byKey(ValueKey(key)));
  await t.tap(find.byKey(ValueKey(key)));
  await t.pumpAndSettle();
}

/// Answers the exercise on screen through the real UI.
/// Leaves the feedback panel open (does not press Continue).
Future<void> answer(WidgetTester t, Exercise ex, {bool correct = true}) async {
  switch (ex) {
    case MultipleChoiceExercise(:final correctIndex, :final options):
      final pick = correct ? correctIndex : (correctIndex + 1) % options.length;
      await _tapKey(t, 'option_$pick');
      await _tapKey(t, 'check_button');
    case TypeAnswerExercise(:final acceptedAnswers):
      await t.enterText(
        find.byKey(const ValueKey('type_answer_field')),
        correct ? acceptedAnswers.first : 'zzz',
      );
      await t.pumpAndSettle();
      await _tapKey(t, 'check_button');
    case BuildSentenceExercise(:final answer, :final tiles):
      final used = <int>{};
      final tokens = correct ? answer : answer.reversed.toList();
      for (final token in tokens) {
        final i = List.generate(
          tiles.length,
          (i) => i,
        ).firstWhere((i) => tiles[i] == token && !used.contains(i));
        used.add(i);
        await _tapKey(t, 'bank_$i');
      }
      await _tapKey(t, 'check_button');
    case MatchPairsExercise(:final pairs):
      for (var i = 0; i < pairs.length; i++) {
        await _tapKey(t, 'match_left_$i');
        await _tapKey(t, 'match_right_$i');
      }
  }
}

Future<void> pressContinue(WidgetTester t) => _tapKey(t, 'continue_button');

/// Plays a full lesson. Indices in [wrongAt] are answered incorrectly once,
/// then answered correctly when they are retried at the end.
Future<void> playLesson(
  WidgetTester t,
  List<Exercise> exercises, {
  Set<int> wrongAt = const {},
}) async {
  final queue = <(Exercise, bool)>[
    for (final (i, e) in exercises.indexed) (e, !wrongAt.contains(i)),
  ];
  final retries = <(Exercise, bool)>[];
  for (final (e, ok) in queue) {
    await answer(t, e, correct: ok);
    await pressContinue(t);
    if (!ok) retries.add((e, true));
  }
  for (final (e, _) in retries) {
    await answer(t, e);
    await pressContinue(t);
  }
}
