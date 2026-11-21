import 'language.dart';

// SHARED CONTRACT — see docs/INTEGRATION_CONTRACTS.md §3.
// Owned by the integration lead. Workstreams may ADD optional fields in a PR;
// they must not rename or remove fields.

/// Text keyed by native-language code ("am", "om"). Keyed by code (not the
/// two-field [Localized]) so more Ethiopian languages can be added as data.
class Translations {
  const Translations(this.byCode);

  final Map<String, String> byCode;

  String? of(NativeLanguage lang) => byCode[lang.code];

  factory Translations.fromJson(Object? json) => Translations(
    json is Map
        ? json.map((k, v) => MapEntry(k as String, v as String))
        : const {},
  );

  Map<String, String> toJson() => byCode;
}

/// Where a piece of media came from and why we may use it.
class MediaLicense {
  const MediaLicense({required this.kind, required this.attribution, this.url});

  /// "original" (made by the team) or an SPDX-style id such as "CC-BY-4.0".
  final String kind;
  final String attribution;
  final String? url;

  factory MediaLicense.fromJson(Map<String, Object?> j) => MediaLicense(
    kind: j['kind']! as String,
    attribution: j['attribution']! as String,
    url: j['url'] as String?,
  );

  Map<String, Object?> toJson() => {
    'kind': kind,
    'attribution': attribution,
    if (url != null) 'url': url,
  };
}

/// One line of dialogue on screen, in milliseconds from the clip start.
class SubtitleSegment {
  const SubtitleSegment({
    required this.id,
    required this.startMs,
    required this.endMs,
    required this.en,
    required this.translations,
    this.speaker,
    this.expressionIds = const [],
  });

  final String id;
  final int startMs;
  final int endMs;
  final String en;
  final Translations translations;
  final String? speaker;

  /// Expressions a learner can tap inside this line.
  final List<String> expressionIds;

  bool activeAt(int positionMs) => positionMs >= startMs && positionMs < endMs;

  factory SubtitleSegment.fromJson(Map<String, Object?> j) => SubtitleSegment(
    id: j['id']! as String,
    startMs: j['startMs']! as int,
    endMs: j['endMs']! as int,
    en: j['en']! as String,
    translations: Translations.fromJson(j['translations']),
    speaker: j['speaker'] as String?,
    expressionIds: [...?(j['expressionIds'] as List?)?.cast<String>()],
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'startMs': startMs,
    'endMs': endMs,
    'en': en,
    'translations': translations.toJson(),
    if (speaker != null) 'speaker': speaker,
    if (expressionIds.isNotEmpty) 'expressionIds': expressionIds,
  };
}

/// A phrase worth learning, with its meaning in context.
class Expression {
  const Expression({
    required this.id,
    required this.en,
    required this.meaning,
    required this.explanation,
    this.example,
    this.reviewed = false,
  });

  final String id;

  /// Exactly as it appears in the English subtitle (used for highlighting).
  final String en;

  /// Short gloss in the learner's language.
  final Translations meaning;

  /// Why it is said this way in THIS scene, in the learner's language.
  final Translations explanation;

  /// Optional extra English example sentence.
  final String? example;

  /// True only after a native speaker has checked the translations.
  final bool reviewed;

  factory Expression.fromJson(Map<String, Object?> j) => Expression(
    id: j['id']! as String,
    en: j['en']! as String,
    meaning: Translations.fromJson(j['meaning']),
    explanation: Translations.fromJson(j['explanation']),
    example: j['example'] as String?,
    reviewed: j['reviewed'] as bool? ?? false,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'en': en,
    'meaning': meaning.toJson(),
    'explanation': explanation.toJson(),
    if (example != null) 'example': example,
    'reviewed': reviewed,
  };
}

/// A short clip plus everything needed to learn from it offline.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.videoAsset,
    required this.durationMs,
    required this.license,
    required this.segments,
    required this.expressions,
    this.posterAsset,
    this.sceneSummary = '',
    this.level = 1,
  });

  static const schemaVersion = 1;

  final String id;
  final String title;

  /// Bundled asset path (e.g. assets/content/media/cafe_order/clip.mp4).
  final String videoAsset;
  final String? posterAsset;
  final int durationMs;
  final MediaLicense license;
  final List<SubtitleSegment> segments;
  final List<Expression> expressions;

  /// Plain-English description of the scene, given to the AI tutor.
  final String sceneSummary;
  final int level;

  Expression? expression(String id) {
    for (final e in expressions) {
      if (e.id == id) return e;
    }
    return null;
  }

  SubtitleSegment? segmentAt(int positionMs) {
    for (final s in segments) {
      if (s.activeAt(positionMs)) return s;
    }
    return null;
  }

  factory MediaItem.fromJson(Map<String, Object?> j) => MediaItem(
    id: j['id']! as String,
    title: j['title']! as String,
    videoAsset: j['videoAsset']! as String,
    posterAsset: j['posterAsset'] as String?,
    durationMs: j['durationMs']! as int,
    license: MediaLicense.fromJson(
      (j['license']! as Map).cast<String, Object?>(),
    ),
    segments: [
      for (final s in j['segments']! as List)
        SubtitleSegment.fromJson((s as Map).cast<String, Object?>()),
    ],
    expressions: [
      for (final e in j['expressions'] as List? ?? const [])
        Expression.fromJson((e as Map).cast<String, Object?>()),
    ],
    sceneSummary: j['sceneSummary'] as String? ?? '',
    level: j['level'] as int? ?? 1,
  );

  Map<String, Object?> toJson() => {
    'v': schemaVersion,
    'id': id,
    'title': title,
    'videoAsset': videoAsset,
    if (posterAsset != null) 'posterAsset': posterAsset,
    'durationMs': durationMs,
    'license': license.toJson(),
    'sceneSummary': sceneSummary,
    'level': level,
    'segments': [for (final s in segments) s.toJson()],
    'expressions': [for (final e in expressions) e.toJson()],
  };
}
