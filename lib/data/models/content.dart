// SHARED CONTRACT (v2) — docs/DATA_MODEL.md, docs/CONTENT_GOVERNANCE.md.
// Pure Dart: no Flutter imports, so content logic is testable and reusable
// by future readers/players (songs, books, articles, podcasts).

import 'language.dart';

/// Kinds of learnable content. Only [video] has a player in the MVP; the
/// rest exist so catalogues and manifests can describe them already.
enum ContentType { video, song, book, article, audioStory, podcast }

enum TranslationStatus {
  /// Written by the team, not yet checked by a native speaker.
  draft,

  /// Checked and approved by a named native-speaker reviewer.
  reviewed,
}

/// Provenance of one translation of one piece of content.
class TranslationInfo {
  const TranslationInfo({
    required this.status,
    this.translator,
    this.reviewer,
    this.reviewedAt,
  });

  final TranslationStatus status;
  final String? translator;
  final String? reviewer;
  final String? reviewedAt;

  bool get isReviewed => status == TranslationStatus.reviewed;

  factory TranslationInfo.fromJson(Map<String, Object?> j) => TranslationInfo(
    status: TranslationStatus.values.byName(j['status']! as String),
    translator: j['translator'] as String?,
    reviewer: j['reviewer'] as String?,
    reviewedAt: j['reviewedAt'] as String?,
  );

  Map<String, Object?> toJson() => {
    'status': status.name,
    if (translator != null) 'translator': translator,
    if (reviewer != null) 'reviewer': reviewer,
    if (reviewedAt != null) 'reviewedAt': reviewedAt,
  };
}

/// Rights and permitted use. Every content item must carry this; the app
/// refuses to list content whose rights forbid offline use when bundled.
class ContentRights {
  const ContentRights({
    required this.creator,
    required this.rightsHolder,
    required this.licenseType,
    required this.attribution,
    required this.offlineUseAllowed,
    required this.derivativeTranslationsAllowed,
    this.source,
    this.licenseUrl,
    this.components = const [],
  });

  final String creator;
  final String rightsHolder;

  /// "original", or an SPDX id such as "CC-BY-4.0".
  final String licenseType;
  final String attribution;
  final bool offlineUseAllowed;
  final bool derivativeTranslationsAllowed;
  final String? source;
  final String? licenseUrl;

  /// Third-party parts (e.g. a synthetic voice model) with their own terms.
  final List<String> components;

  factory ContentRights.fromJson(Map<String, Object?> j) => ContentRights(
    creator: j['creator']! as String,
    rightsHolder: j['rightsHolder']! as String,
    licenseType: j['licenseType']! as String,
    attribution: j['attribution']! as String,
    offlineUseAllowed: j['offlineUseAllowed']! as bool,
    derivativeTranslationsAllowed: j['derivativeTranslationsAllowed']! as bool,
    source: j['source'] as String?,
    licenseUrl: j['licenseUrl'] as String?,
    components: [...?(j['components'] as List?)?.cast<String>()],
  );
}

enum MediaType { video, audio }

/// The playable file behind a piece of content.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.contentId,
    required this.mediaType,
    required this.durationMs,
    this.localAsset,
    this.remoteUrl,
    this.posterAsset,
  });

  final String id;
  final String contentId;
  final MediaType mediaType;
  final int durationMs;

  /// Bundled asset path (offline). Null for remote-only media.
  final String? localAsset;

  /// Future streaming/download source; unused in the MVP.
  final String? remoteUrl;
  final String? posterAsset;

  factory MediaItem.fromJson(String contentId, Map<String, Object?> j) =>
      MediaItem(
        id: j['id']! as String,
        contentId: contentId,
        mediaType: MediaType.values.byName(j['type']! as String),
        durationMs: j['durationMs']! as int,
        localAsset: j['localAsset'] as String?,
        remoteUrl: j['remoteUrl'] as String?,
        posterAsset: j['posterAsset'] as String?,
      );
}

/// A learnable phrase inside a transcript, with its meaning in context.
class Expression {
  const Expression({
    required this.id,
    required this.text,
    required this.segmentId,
    required this.meaning,
    required this.contextualMeaning,
    required this.example,
    this.exampleTranslation = const {},
  });

  final String id;

  /// Exactly as it appears in the source segment (used for highlighting).
  final String text;
  final String segmentId;

  /// Short gloss per language code.
  final Map<String, String> meaning;

  /// Why it is said this way in THIS scene, per language code.
  final Map<String, String> contextualMeaning;
  final String example;
  final Map<String, String> exampleTranslation;

  String? meaningIn(NativeLanguage l) => meaning[l.code];
  String? contextIn(NativeLanguage l) => contextualMeaning[l.code];
}

/// A catalogue entry. Source content and its translations are stored
/// separately (manifest + transcript + translations/<code>.json).
class LearningContent {
  const LearningContent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.sourceLanguage,
    required this.translations,
    required this.difficulty,
    required this.durationMs,
    required this.rights,
    required this.offlineAvailable,
    required this.contentVersion,
    required this.media,
    required this.transcriptAsset,
    this.sceneSummary = '',
    this.speakers = const {},
  });

  static const schemaVersion = 2;

  final String id;
  final ContentType type;
  final String title;
  final String description;
  final String sourceLanguage;

  /// Language code -> translation provenance. Keys are the supported
  /// translation languages; the files live next to the manifest.
  final Map<String, TranslationInfo> translations;
  final int difficulty;
  final int durationMs;
  final ContentRights rights;
  final bool offlineAvailable;
  final int contentVersion;
  final MediaItem media;
  final String transcriptAsset;

  /// Plain-English scene description, given to the AI tutor.
  final String sceneSummary;

  /// speakerId -> display name.
  final Map<String, String> speakers;

  bool supportsTranslation(NativeLanguage l) =>
      translations.containsKey(l.code);

  TranslationInfo? translationInfo(NativeLanguage l) => translations[l.code];

  factory LearningContent.fromJson(Map<String, Object?> j) {
    final v = j['schemaVersion'] as int? ?? 0;
    if (v != schemaVersion) {
      throw FormatException('Unsupported content schema $v');
    }
    final id = j['id']! as String;
    return LearningContent(
      id: id,
      type: ContentType.values.byName(j['type']! as String),
      title: j['title']! as String,
      description: j['description'] as String? ?? '',
      sourceLanguage: j['sourceLanguage']! as String,
      translations: {
        for (final e in (j['translations']! as Map).entries)
          e.key as String: TranslationInfo.fromJson(
            (e.value as Map).cast<String, Object?>(),
          ),
      },
      difficulty: j['difficulty'] as int? ?? 1,
      durationMs: j['durationMs']! as int,
      rights: ContentRights.fromJson(
        (j['rights']! as Map).cast<String, Object?>(),
      ),
      offlineAvailable: j['offlineAvailable'] as bool? ?? false,
      contentVersion: j['contentVersion'] as int? ?? 1,
      media: MediaItem.fromJson(
        id,
        (j['media']! as Map).cast<String, Object?>(),
      ),
      transcriptAsset: j['transcript']! as String,
      sceneSummary: j['sceneSummary'] as String? ?? '',
      speakers: ((j['speakers'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, v as String),
      ),
    );
  }
}
