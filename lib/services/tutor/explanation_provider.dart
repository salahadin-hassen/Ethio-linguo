import '../../data/models/content.dart';
import '../../data/models/language.dart';

/// A contextual explanation of an expression for one learner language.
class ContextualExplanation {
  const ContextualExplanation({
    required this.expression,
    required this.meaning,
    required this.inContext,
    required this.example,
    this.exampleTranslation,
    required this.authoritative,
  });

  final String expression;
  final String? meaning;
  final String? inContext;
  final String example;
  final String? exampleTranslation;

  /// True for curated content; false for anything AI-generated, which the UI
  /// must label and never present as verified teaching content.
  final bool authoritative;
}

/// Explanation source. MVP: curated, bundled, offline. A future AI-assisted
/// provider can fill gaps for new content but stays non-authoritative.
abstract interface class ExplanationProvider {
  Future<ContextualExplanation> explain(Expression e, NativeLanguage lang);
}

class BundledExplanationProvider implements ExplanationProvider {
  const BundledExplanationProvider();

  @override
  Future<ContextualExplanation> explain(
    Expression e,
    NativeLanguage lang,
  ) async => ContextualExplanation(
    expression: e.text,
    meaning: e.meaningIn(lang),
    inContext: e.contextIn(lang),
    example: e.example,
    exampleTranslation: e.exampleTranslation[lang.code],
    authoritative: true,
  );
}
