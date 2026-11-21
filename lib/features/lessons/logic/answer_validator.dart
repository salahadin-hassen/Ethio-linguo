import '../../../data/models/exercise.dart';

enum Verdict { correct, almost, incorrect }

/// Pure, local answer checking. No network, no randomness.
abstract final class AnswerValidator {
  /// Lower-cases, trims, strips punctuation and collapses whitespace.
  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[.,!?;:'’’።፣፤፧፨]"), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Verdict checkChoice(MultipleChoiceExercise e, int? selected) =>
      selected == e.correctIndex ? Verdict.correct : Verdict.incorrect;

  /// Exact (normalised) match is correct. A single-letter typo on a word of
  /// five or more letters is accepted as [Verdict.almost] so beginners are
  /// nudged on spelling rather than punished.
  static Verdict checkTyped(TypeAnswerExercise e, String input) {
    final given = normalize(input);
    if (given.isEmpty) return Verdict.incorrect;
    for (final a in e.acceptedAnswers) {
      final want = normalize(a);
      if (given == want ||
          given.replaceAll(' ', '') == want.replaceAll(' ', '')) {
        return Verdict.correct;
      }
    }
    for (final a in e.acceptedAnswers) {
      final want = normalize(a);
      if (want.length >= 5 && _editDistance(given, want) <= 1) {
        return Verdict.almost;
      }
    }
    return Verdict.incorrect;
  }

  static Verdict checkSentence(BuildSentenceExercise e, List<String> tokens) {
    final given = normalize(tokens.join(' '));
    final want = normalize(e.answer.join(' '));
    return given == want ? Verdict.correct : Verdict.incorrect;
  }

  static bool isMatch(
    MatchPairsExercise e,
    int leftIndex,
    int rightPairIndex,
  ) => leftIndex == rightPairIndex;

  /// Optimal-string-alignment distance: insert, delete, substitute and
  /// swap of adjacent letters each cost 1 ("freind" -> "friend" = 1).
  static int _editDistance(String a, String b) {
    if ((a.length - b.length).abs() > 1) return 2;
    final d = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );
    for (var i = 0; i <= a.length; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      d[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        var v = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
        if (i > 1 &&
            j > 1 &&
            a[i - 1] == b[j - 2] &&
            a[i - 2] == b[j - 1] &&
            d[i - 2][j - 2] + 1 < v) {
          v = d[i - 2][j - 2] + 1;
        }
        d[i][j] = v;
      }
    }
    return d[a.length][b.length];
  }
}
