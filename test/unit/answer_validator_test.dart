import 'package:ethio_linguo/data/models/exercise.dart';
import 'package:ethio_linguo/features/lessons/logic/answer_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mc = MultipleChoiceExercise(
    id: 'mc',
    instruction: '',
    nativeInstruction: '',
    termIds: ['coffee'],
    prompt: 'ቡና',
    options: ['water', 'coffee', 'tea'],
    correctIndex: 1,
  );
  const typed = TypeAnswerExercise(
    id: 't',
    instruction: '',
    nativeInstruction: '',
    termIds: ['thank_you'],
    prompt: 'አመሰግናለሁ',
    acceptedAnswers: ['thank you', 'thanks'],
  );
  const friend = TypeAnswerExercise(
    id: 'f',
    instruction: '',
    nativeInstruction: '',
    termIds: ['friend'],
    prompt: 'ጓደኛ',
    acceptedAnswers: ['friend'],
  );
  const sentence = BuildSentenceExercise(
    id: 's',
    instruction: '',
    nativeInstruction: '',
    termIds: [],
    prompt: 'ቡና እና ዳቦ',
    answer: ['Coffee', 'and', 'bread'],
    tiles: ['bread', 'Coffee', 'and', 'water'],
  );

  group('multiple choice', () {
    test(
      'correct index passes',
      () => expect(AnswerValidator.checkChoice(mc, 1), Verdict.correct),
    );
    test(
      'wrong index fails',
      () => expect(AnswerValidator.checkChoice(mc, 0), Verdict.incorrect),
    );
    test(
      'no selection fails',
      () => expect(AnswerValidator.checkChoice(mc, null), Verdict.incorrect),
    );
  });

  group('typed answers', () {
    test(
      'exact',
      () => expect(
        AnswerValidator.checkTyped(typed, 'thank you'),
        Verdict.correct,
      ),
    );
    test('case, punctuation and spacing are ignored', () {
      expect(
        AnswerValidator.checkTyped(typed, '  Thank   YOU! '),
        Verdict.correct,
      );
      expect(AnswerValidator.checkTyped(typed, 'thankyou'), Verdict.correct);
    });
    test(
      'alternative accepted answer',
      () =>
          expect(AnswerValidator.checkTyped(typed, 'Thanks.'), Verdict.correct),
    );
    test('one-letter typo on long word is "almost"', () {
      expect(
        AnswerValidator.checkTyped(friend, 'freind'),
        Verdict.almost,
      ); // transposition
      expect(
        AnswerValidator.checkTyped(friend, 'frend'),
        Verdict.almost,
      ); // deletion
      expect(
        AnswerValidator.checkTyped(friend, 'friendd'),
        Verdict.almost,
      ); // insertion
    });
    test('two errors or a different word is incorrect', () {
      expect(AnswerValidator.checkTyped(friend, 'frnd'), Verdict.incorrect);
      expect(AnswerValidator.checkTyped(friend, 'water'), Verdict.incorrect);
    });
    test(
      'empty input is incorrect',
      () =>
          expect(AnswerValidator.checkTyped(friend, '   '), Verdict.incorrect),
    );
    test(
      'normalize strips Ethiopic punctuation',
      () => expect(AnswerValidator.normalize('ሰላም።'), 'ሰላም'),
    );
  });

  group('sentence building', () {
    test(
      'right order passes',
      () => expect(
        AnswerValidator.checkSentence(sentence, ['Coffee', 'and', 'bread']),
        Verdict.correct,
      ),
    );
    test(
      'wrong order fails',
      () => expect(
        AnswerValidator.checkSentence(sentence, ['bread', 'and', 'Coffee']),
        Verdict.incorrect,
      ),
    );
    test(
      'extra distractor fails',
      () => expect(
        AnswerValidator.checkSentence(sentence, [
          'Coffee',
          'and',
          'bread',
          'water',
        ]),
        Verdict.incorrect,
      ),
    );
    test(
      'incomplete fails',
      () => expect(
        AnswerValidator.checkSentence(sentence, ['Coffee']),
        Verdict.incorrect,
      ),
    );
  });

  test('match pairs compares pair identity', () {
    const m = MatchPairsExercise(
      id: 'm',
      instruction: '',
      nativeInstruction: '',
      termIds: [],
      pairs: [MatchPair('a', 'ቡና', 'coffee'), MatchPair('b', 'ውሃ', 'water')],
      rightOrder: [1, 0],
    );
    expect(AnswerValidator.isMatch(m, 0, 0), isTrue);
    expect(AnswerValidator.isMatch(m, 0, 1), isFalse);
  });
}
