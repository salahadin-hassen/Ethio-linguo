import 'media.dart';

// SHARED CONTRACT — see docs/INTEGRATION_CONTRACTS.md §4.

/// Where a saved expression came from.
enum ExpressionSource { media, tutor, lesson }

/// An expression the learner saved to My Words, with the context it was
/// met in. Lesson vocabulary keeps living in LearnerProgress.words (the Word
/// Garden); this is the separate, context-rich list.
class SavedExpression {
  const SavedExpression({
    required this.id,
    required this.en,
    required this.meaning,
    required this.source,
    required this.savedAt,
    this.contextLine,
    this.mediaId,
    this.segmentId,
    this.reviewCount = 0,
  });

  /// Same id as the [Expression] it came from, so saving twice is a no-op.
  final String id;
  final String en;
  final Translations meaning;
  final ExpressionSource source;

  /// ISO-8601 timestamp.
  final String savedAt;

  /// The full English line the expression appeared in.
  final String? contextLine;
  final String? mediaId;
  final String? segmentId;
  final int reviewCount;

  factory SavedExpression.fromMedia({
    required MediaItem media,
    required SubtitleSegment segment,
    required Expression expression,
    required DateTime now,
  }) => SavedExpression(
    id: expression.id,
    en: expression.en,
    meaning: expression.meaning,
    source: ExpressionSource.media,
    savedAt: now.toIso8601String(),
    contextLine: segment.en,
    mediaId: media.id,
    segmentId: segment.id,
  );

  SavedExpression copyWith({int? reviewCount}) => SavedExpression(
    id: id,
    en: en,
    meaning: meaning,
    source: source,
    savedAt: savedAt,
    contextLine: contextLine,
    mediaId: mediaId,
    segmentId: segmentId,
    reviewCount: reviewCount ?? this.reviewCount,
  );

  factory SavedExpression.fromJson(Map<String, Object?> j) => SavedExpression(
    id: j['id']! as String,
    en: j['en']! as String,
    meaning: Translations.fromJson(j['meaning']),
    source: ExpressionSource.values.byName(j['source']! as String),
    savedAt: j['savedAt']! as String,
    contextLine: j['contextLine'] as String?,
    mediaId: j['mediaId'] as String?,
    segmentId: j['segmentId'] as String?,
    reviewCount: j['reviewCount'] as int? ?? 0,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'en': en,
    'meaning': meaning.toJson(),
    'source': source.name,
    'savedAt': savedAt,
    if (contextLine != null) 'contextLine': contextLine,
    if (mediaId != null) 'mediaId': mediaId,
    if (segmentId != null) 'segmentId': segmentId,
    'reviewCount': reviewCount,
  };
}
