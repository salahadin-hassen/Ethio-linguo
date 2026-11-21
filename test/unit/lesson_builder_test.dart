import 'package:ethio_linguo/data/local/demo_course.dart';
import 'package:ethio_linguo/data/models/course.dart';
import 'package:ethio_linguo/data/models/exercise.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/features/lessons/logic/lesson_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final lang in NativeLanguage.values) {
    group('content for ${lang.englishName}', () {
      for (final lesson in DemoCourse.lessons.values) {
        test('${lesson.id} resolves into valid exercises', () {
          final exs = LessonBuilder(
            DemoCourse.course,
            lang,
          ).buildLesson(lesson);
          expect(exs, hasLength(lesson.exercises.length));
          final kinds = exs.map((e) => e.runtimeType).toSet();
          expect(
            kinds,
            containsAll([
              MultipleChoiceExercise,
              TypeAnswerExercise,
              BuildSentenceExercise,
              MatchPairsExercise,
            ]),
          );
          for (final e in exs) {
            expect(e.nativeInstruction, isNotEmpty);
            switch (e) {
              case MultipleChoiceExercise(:final options, :final correctIndex):
                expect(
                  options.toSet(),
                  hasLength(options.length),
                  reason: 'no duplicate options',
                );
                expect(correctIndex, inInclusiveRange(0, options.length - 1));
              case BuildSentenceExercise(:final answer, :final tiles):
                for (final tok in answer) {
                  expect(tiles, contains(tok));
                }
              case MatchPairsExercise(:final pairs, :final rightOrder):
                expect(rightOrder.toSet(), {
                  for (var i = 0; i < pairs.length; i++) i,
                });
              case TypeAnswerExercise(:final acceptedAnswers):
                expect(acceptedAnswers, isNotEmpty);
            }
          }
        });
      }

      test('practice and checkpoint reviews generate content', () {
        for (final n in DemoCourse.course.allNodes.where(
          (n) => n.reviewTermIds.isNotEmpty,
        )) {
          final exs = LessonBuilder(DemoCourse.course, lang).buildReview(
            n.reviewTermIds,
            id: n.id,
            checkpoint: n.kind == NodeKind.checkpoint,
          );
          expect(exs.length, greaterThanOrEqualTo(5), reason: n.id);
        }
      });
    });
  }

  test('build is deterministic for a seed', () {
    final a = LessonBuilder(
      DemoCourse.course,
      NativeLanguage.amharic,
    ).buildLesson(DemoCourse.lessons['l_coffee']!);
    final b = LessonBuilder(
      DemoCourse.course,
      NativeLanguage.amharic,
    ).buildLesson(DemoCourse.lessons['l_coffee']!);
    expect(a.map((e) => e.solutionText), b.map((e) => e.solutionText));
  });

  test('empty review returns no exercises (handled by empty state)', () {
    expect(
      LessonBuilder(
        DemoCourse.course,
        NativeLanguage.oromo,
      ).buildReview(const [], id: 'x'),
      isEmpty,
    );
  });
}
