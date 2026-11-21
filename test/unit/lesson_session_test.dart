import 'package:ethio_linguo/data/models/exercise.dart';
import 'package:ethio_linguo/features/lessons/logic/answer_validator.dart';
import 'package:ethio_linguo/features/lessons/logic/lesson_session.dart';
import 'package:flutter_test/flutter_test.dart';

MultipleChoiceExercise ex(String id) => MultipleChoiceExercise(
  id: id,
  instruction: '',
  nativeInstruction: '',
  termIds: [id],
  prompt: id,
  options: const ['a', 'b'],
  correctIndex: 0,
);

void main() {
  test('all correct: progress reaches 1, perfect, no hearts lost', () {
    final s = LessonSession(
      nodeId: 'n',
      exercises: [ex('a'), ex('b')],
      hearts: 5,
    );
    expect(s.progress, 0);
    s.submit(Verdict.correct);
    expect(s.phase, SessionPhase.feedback);
    s.next();
    expect(s.progress, 0.5);
    s.submit(Verdict.correct);
    s.next();
    expect(s.phase, SessionPhase.finished);
    final r = s.result();
    expect(r.perfect, isTrue);
    expect(r.correctFirstTry, 2);
    expect(r.heartsLeft, 5);
    expect(r.correctTermIds, {'a', 'b'});
  });

  test('mistake costs a heart and is retried once at the end', () {
    final lost = <int>[];
    final s = LessonSession(
      nodeId: 'n',
      exercises: [ex('a'), ex('b')],
      hearts: 3,
      onHeartLost: lost.add,
    );
    s.submit(Verdict.incorrect);
    expect(s.hearts, 2);
    expect(lost, [2]);
    expect(s.progress, 0, reason: 'a wrong answer does not advance progress');
    s.next();
    s.submit(Verdict.correct);
    s.next();
    expect(s.phase, SessionPhase.answering);
    expect(s.isRetry, isTrue);
    expect(s.current.id, 'a');
    s.submit(Verdict.correct);
    s.next();
    expect(s.phase, SessionPhase.finished);
    final r = s.result();
    expect(r.mistakes, 1);
    expect(r.correctFirstTry, 1);
    expect(r.missedTermIds, {'a'});
    expect(r.correctTermIds, {
      'b',
    }, reason: 'retried words do not count as mastered');
  });

  test('repeated failure does not loop forever', () {
    final s = LessonSession(nodeId: 'n', exercises: [ex('a')], hearts: 5);
    s.submit(Verdict.incorrect);
    s.next();
    s.submit(Verdict.incorrect);
    s.next();
    expect(s.phase, SessionPhase.finished);
  });

  test('zero hearts switches to practice mode instead of ending', () {
    final s = LessonSession(
      nodeId: 'n',
      exercises: [ex('a'), ex('b')],
      hearts: 1,
    );
    s.submit(Verdict.incorrect);
    expect(s.hearts, 0);
    expect(s.practiceMode, isTrue);
    s.next();
    s.submit(Verdict.incorrect);
    expect(s.hearts, 0, reason: 'hearts never go negative');
    s.next();
    expect(s.phase, SessionPhase.answering, reason: 'lesson continues');
  });

  test('"almost" counts as correct', () {
    final s = LessonSession(nodeId: 'n', exercises: [ex('a')], hearts: 5);
    s.submit(Verdict.almost);
    expect(s.hearts, 5);
    s.next();
    expect(s.result().perfect, isTrue);
  });

  test('submit is ignored outside the answering phase', () {
    final s = LessonSession(nodeId: 'n', exercises: [ex('a')], hearts: 5);
    s.submit(Verdict.correct);
    s.submit(Verdict.incorrect);
    expect(s.mistakes, 0);
  });
}
