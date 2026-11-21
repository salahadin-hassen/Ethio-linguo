// SHARED CONTRACT (v2) — docs/DATA_MODEL.md §Vocabulary.

import 'content.dart';
import 'language.dart';
import 'transcript.dart';

enum MasteryStatus { learning, familiar, mastered }

enum VocabularySource { media, tutor, lesson }

/// One saved expression in My Words.
///
/// Sync-ready but not synced: ids are generated locally, every write bumps
/// [updatedAt], and [dirty] marks changes no server has seen yet. There is no
/// sync engine in the MVP and the UI never claims there is.
class VocabularyEntry {
  const VocabularyEntry({
    required this.id,
    required this.learnerId,
    required this.originalExpression,
    required this.translations,
    required this.contextualMeaning,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.expressionId,
    this.example,
    this.contextLine,
    this.contextTranslations = const {},
    this.sourceContentId,
    this.sourceContentTitle,
    this.sourceSegmentId,
    this.masteryStatus = MasteryStatus.learning,
    this.nextReviewAt,
    this.reviewCount = 0,
    this.dirty = true,
  });

  final String id;
  final String learnerId;

  /// The content expression this came from (dedupe key), if any.
  final String? expressionId;
  final String originalExpression;
  final Map<String, String> translations;
  final Map<String, String> contextualMeaning;
  final String? example;
  final String? contextLine;
  final Map<String, String> contextTranslations;
  final VocabularySource source;
  final String? sourceContentId;
  final String? sourceContentTitle;
  final String? sourceSegmentId;
  final MasteryStatus masteryStatus;

  /// UTC timestamps.
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextReviewAt;
  final int reviewCount;
  final bool dirty;

  String? meaningIn(NativeLanguage l) => translations[l.code];

  bool isDue(DateTime now) =>
      nextReviewAt == null || !now.isBefore(nextReviewAt!);

  factory VocabularyEntry.fromExpression({
    required String id,
    required String learnerId,
    required LearningContent content,
    required TranscriptSegment segment,
    required Expression expression,
    required DateTime now,
  }) => VocabularyEntry(
    id: id,
    learnerId: learnerId,
    expressionId: expression.id,
    originalExpression: expression.text,
    translations: expression.meaning,
    contextualMeaning: expression.contextualMeaning,
    example: expression.example,
    contextLine: segment.originalText,
    contextTranslations: segment.translations,
    source: VocabularySource.media,
    sourceContentId: content.id,
    sourceContentTitle: content.title,
    sourceSegmentId: segment.id,
    createdAt: now.toUtc(),
    updatedAt: now.toUtc(),
    nextReviewAt: now.toUtc(),
  );

  /// Simple fixed-interval (Leitner-style) scheduling. Deliberately not
  /// adaptive: good enough for the MVP, replaceable later.
  VocabularyEntry reviewed({required bool remembered, required DateTime now}) {
    final next = switch ((remembered, masteryStatus)) {
      (false, _) => MasteryStatus.learning,
      (true, MasteryStatus.learning) => MasteryStatus.familiar,
      (true, _) => MasteryStatus.mastered,
    };
    final days = switch (next) {
      MasteryStatus.learning => 1,
      MasteryStatus.familiar => 3,
      MasteryStatus.mastered => 7,
    };
    return _copy(
      masteryStatus: next,
      reviewCount: reviewCount + 1,
      nextReviewAt: now.toUtc().add(Duration(days: days)),
      updatedAt: now.toUtc(),
    );
  }

  VocabularyEntry _copy({
    MasteryStatus? masteryStatus,
    int? reviewCount,
    DateTime? nextReviewAt,
    DateTime? updatedAt,
  }) => VocabularyEntry(
    id: id,
    learnerId: learnerId,
    expressionId: expressionId,
    originalExpression: originalExpression,
    translations: translations,
    contextualMeaning: contextualMeaning,
    example: example,
    contextLine: contextLine,
    contextTranslations: contextTranslations,
    source: source,
    sourceContentId: sourceContentId,
    sourceContentTitle: sourceContentTitle,
    sourceSegmentId: sourceSegmentId,
    masteryStatus: masteryStatus ?? this.masteryStatus,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    reviewCount: reviewCount ?? this.reviewCount,
    dirty: true,
  );

  static Map<String, String> _map(Object? j) =>
      j is Map ? j.map((k, v) => MapEntry(k as String, v as String)) : const {};

  factory VocabularyEntry.fromJson(Map<String, Object?> j) => VocabularyEntry(
    id: j['id']! as String,
    learnerId: j['learnerId']! as String,
    expressionId: j['expressionId'] as String?,
    originalExpression: j['originalExpression']! as String,
    translations: _map(j['translations']),
    contextualMeaning: _map(j['contextualMeaning']),
    example: j['example'] as String?,
    contextLine: j['contextLine'] as String?,
    contextTranslations: _map(j['contextTranslations']),
    source: VocabularySource.values.byName(j['source']! as String),
    sourceContentId: j['sourceContentId'] as String?,
    sourceContentTitle: j['sourceContentTitle'] as String?,
    sourceSegmentId: j['sourceSegmentId'] as String?,
    masteryStatus: MasteryStatus.values.byName(
      j['masteryStatus'] as String? ?? 'learning',
    ),
    createdAt: DateTime.parse(j['createdAt']! as String),
    updatedAt: DateTime.parse(j['updatedAt']! as String),
    nextReviewAt: j['nextReviewAt'] == null
        ? null
        : DateTime.parse(j['nextReviewAt']! as String),
    reviewCount: j['reviewCount'] as int? ?? 0,
    dirty: j['dirty'] as bool? ?? true,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'learnerId': learnerId,
    'expressionId': ?expressionId,
    'originalExpression': originalExpression,
    'translations': translations,
    'contextualMeaning': contextualMeaning,
    'example': ?example,
    'contextLine': ?contextLine,
    'contextTranslations': contextTranslations,
    'source': source.name,
    'sourceContentId': ?sourceContentId,
    'sourceContentTitle': ?sourceContentTitle,
    'sourceSegmentId': ?sourceSegmentId,
    'masteryStatus': masteryStatus.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'nextReviewAt': ?nextReviewAt?.toIso8601String(),
    'reviewCount': reviewCount,
    'dirty': dirty,
  };
}
