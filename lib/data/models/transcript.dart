// SHARED CONTRACT (v2). Pure Dart — subtitle sync logic lives here, not in
// widgets, so songs (lyrics) and audio stories can reuse it.

import 'content.dart';
import 'language.dart';

/// One timed line of source text plus its translations.
class TranscriptSegment {
  const TranscriptSegment({
    required this.id,
    required this.mediaId,
    required this.startMs,
    required this.endMs,
    required this.originalText,
    this.speakerId,
    this.translations = const {},
    this.expressionIds = const [],
  });

  final String id;
  final String mediaId;
  final int startMs;

  /// Exclusive.
  final int endMs;
  final String originalText;
  final String? speakerId;

  /// Language code -> translated line (merged from translations/<code>.json).
  final Map<String, String> translations;
  final List<String> expressionIds;

  bool activeAt(int ms) => ms >= startMs && ms < endMs;

  String? translationIn(NativeLanguage l) => translations[l.code];

  TranscriptSegment withTranslation(String code, String text) =>
      TranscriptSegment(
        id: id,
        mediaId: mediaId,
        startMs: startMs,
        endMs: endMs,
        originalText: originalText,
        speakerId: speakerId,
        translations: {...translations, code: text},
        expressionIds: expressionIds,
      );
}

/// Ordered, validated segments + expressions for one media item.
class Transcript {
  Transcript({
    required this.mediaId,
    required this.language,
    required List<TranscriptSegment> segments,
    required this.expressions,
  }) : segments = List.unmodifiable(segments) {
    for (var i = 0; i < this.segments.length; i++) {
      final s = this.segments[i];
      if (s.endMs <= s.startMs) {
        throw FormatException('Segment ${s.id} has non-positive duration');
      }
      if (i > 0 && s.startMs < this.segments[i - 1].endMs) {
        throw FormatException('Segment ${s.id} overlaps the previous one');
      }
    }
    for (final e in expressions) {
      final seg = segmentById(e.segmentId);
      if (seg == null || !seg.originalText.contains(e.text)) {
        throw FormatException('Expression ${e.id} not found in its segment');
      }
    }
  }

  final String mediaId;
  final String language;
  final List<TranscriptSegment> segments;
  final List<Expression> expressions;

  /// Binary search: the segment on screen at [ms], or null between lines.
  TranscriptSegment? segmentAt(int ms) {
    var lo = 0, hi = segments.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final s = segments[mid];
      if (ms < s.startMs) {
        hi = mid - 1;
      } else if (ms >= s.endMs) {
        lo = mid + 1;
      } else {
        return s;
      }
    }
    return null;
  }

  /// The segment at [ms], or the most recent one before it (for "replay").
  TranscriptSegment? segmentAtOrBefore(int ms) {
    TranscriptSegment? last;
    for (final s in segments) {
      if (s.startMs > ms) break;
      last = s;
    }
    return last;
  }

  int indexOf(TranscriptSegment s) => segments.indexOf(s);

  TranscriptSegment? segmentById(String id) {
    for (final s in segments) {
      if (s.id == id) return s;
    }
    return null;
  }

  Expression? expression(String id) {
    for (final e in expressions) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<Expression> expressionsIn(TranscriptSegment s) => [
    for (final id in s.expressionIds) ?expression(id),
  ];
}

/// Splits a line into plain and expression spans for highlighting.
/// Pure function so the widget stays dumb and this stays testable.
List<({String text, Expression? expression})> spansFor(
  String line,
  List<Expression> expressions,
) {
  final hits = <({int start, Expression e})>[];
  for (final e in expressions) {
    final i = line.indexOf(e.text);
    if (i >= 0) hits.add((start: i, e: e));
  }
  hits.sort((a, b) => a.start.compareTo(b.start));
  final out = <({String text, Expression? expression})>[];
  var cursor = 0;
  for (final h in hits) {
    if (h.start < cursor) continue; // overlapping expressions: first wins
    if (h.start > cursor) {
      out.add((text: line.substring(cursor, h.start), expression: null));
    }
    out.add((text: h.e.text, expression: h.e));
    cursor = h.start + h.e.text.length;
  }
  if (cursor < line.length) {
    out.add((text: line.substring(cursor), expression: null));
  }
  return out;
}
