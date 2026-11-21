import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/content.dart';
import '../models/transcript.dart';

// SHARED CONTRACT (v2) — docs/INTEGRATION_CONTRACTS.md §5.
// Local implementations read bundled assets. Remote/downloaded catalogues
// implement the same interfaces later; screens never change.

abstract interface class LearningContentRepository {
  /// Content the learner may use right now (rights-checked).
  Future<List<LearningContent>> list();
  Future<LearningContent?> byId(String id);
}

abstract interface class TranscriptRepository {
  /// Source transcript merged with the translations for [languages]
  /// (language codes). Missing translations are simply absent.
  Future<Transcript> load(
    LearningContent content, {
    required List<String> languages,
  });
}

enum DownloadState { bundled, downloaded, notDownloaded }

/// Where a piece of content lives on the device. The MVP bundles content in
/// the APK, so everything listed is [DownloadState.bundled].
abstract interface class DownloadRepository {
  Future<DownloadState> stateOf(LearningContent content);
}

/// Reads `assets/content/catalog.json` -> one manifest per item.
class BundledContentRepository implements LearningContentRepository {
  BundledContentRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const catalogPath = 'assets/content/catalog.json';
  final AssetBundle _bundle;
  List<LearningContent>? _loaded;
  Future<List<LearningContent>>? _pending;

  /// Cached results are returned synchronously (no loading flash).
  @override
  Future<List<LearningContent>> list() => _loaded != null
      ? SynchronousFuture(_loaded!)
      : (_pending ??= _load().then((v) => _loaded = v));

  Future<List<LearningContent>> _load() async {
    final catalog = jsonDecode(await _bundle.loadString(catalogPath)) as Map;
    final out = <LearningContent>[];
    for (final path in (catalog['items'] as List).cast<String>()) {
      try {
        final j = jsonDecode(await _bundle.loadString(path)) as Map;
        final c = LearningContent.fromJson(j.cast<String, Object?>());
        // Governance gate: bundled content must permit offline use.
        if (c.rights.offlineUseAllowed) out.add(c);
      } catch (e) {
        debugPrint('content: skipped $path ($e)');
      }
    }
    return out;
  }

  @override
  Future<LearningContent?> byId(String id) async {
    for (final c in await list()) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Transcript file: `{"mediaId","language","segments":[...],"expressions":[...]}`.
/// Translation files: `translations/<code>.json` next to it:
/// `{"language","segments":{id:text},"expressions":{id:{meaning,context,example}}}`.
class BundledTranscriptRepository implements TranscriptRepository {
  BundledTranscriptRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _loaded = <String, Transcript>{};
  final _pending = <String, Future<Transcript>>{};

  @override
  Future<Transcript> load(
    LearningContent content, {
    required List<String> languages,
  }) {
    final key =
        '${content.id}@${content.contentVersion}:${languages.join(',')}';
    final hit = _loaded[key];
    if (hit != null) return SynchronousFuture(hit);
    return _pending.putIfAbsent(
      key,
      () => _load(content, languages).then((t) => _loaded[key] = t),
    );
  }

  Future<Transcript> _load(
    LearningContent content,
    List<String> languages,
  ) async {
    final src = (jsonDecode(
      await _bundle.loadString(content.transcriptAsset),
    ) as Map).cast<String, Object?>();
    final dir = content.transcriptAsset.substring(
      0,
      content.transcriptAsset.lastIndexOf('/') + 1,
    );
    final segText = <String, Map<String, String>>{};
    final exp = <String, Map<String, Map<String, String>>>{};
    for (final code in languages) {
      if (!content.translations.containsKey(code)) continue;
      try {
        final t = (jsonDecode(
          await _bundle.loadString('${dir}translations/$code.json'),
        ) as Map).cast<String, Object?>();
        for (final e in (t['segments'] as Map).entries) {
          (segText[e.key as String] ??= {})[code] = e.value as String;
        }
        for (final e in ((t['expressions'] as Map?) ?? const {}).entries) {
          final v = (e.value as Map).cast<String, String>();
          (exp[e.key as String] ??= {})[code] = v;
        }
      } catch (e) {
        debugPrint('transcript: missing $code translation ($e)');
      }
    }
    final mediaId = src['mediaId']! as String;
    return Transcript(
      mediaId: mediaId,
      language: src['language']! as String,
      segments: [
        for (final raw in src['segments']! as List)
          _segment(mediaId, (raw as Map).cast<String, Object?>(), segText),
      ],
      expressions: [
        for (final raw in (src['expressions'] as List? ?? const []))
          _expression((raw as Map).cast<String, Object?>(), exp),
      ],
    );
  }

  TranscriptSegment _segment(
    String mediaId,
    Map<String, Object?> j,
    Map<String, Map<String, String>> tr,
  ) {
    final id = j['id']! as String;
    return TranscriptSegment(
      id: id,
      mediaId: mediaId,
      startMs: j['startMs']! as int,
      endMs: j['endMs']! as int,
      originalText: j['text']! as String,
      speakerId: j['speakerId'] as String?,
      translations: tr[id] ?? const {},
      expressionIds: [...?(j['expressionIds'] as List?)?.cast<String>()],
    );
  }

  Expression _expression(
    Map<String, Object?> j,
    Map<String, Map<String, Map<String, String>>> tr,
  ) {
    final id = j['id']! as String;
    final t = tr[id] ?? const {};
    Map<String, String> pick(String key) => {
      for (final e in t.entries)
        if (e.value[key] != null) e.key: e.value[key]!,
    };
    return Expression(
      id: id,
      text: j['text']! as String,
      segmentId: j['segmentId']! as String,
      example: j['example']! as String,
      meaning: pick('meaning'),
      contextualMeaning: pick('context'),
      exampleTranslation: pick('example'),
    );
  }
}

class BundledDownloadRepository implements DownloadRepository {
  const BundledDownloadRepository();

  @override
  Future<DownloadState> stateOf(LearningContent content) => SynchronousFuture(
    content.media.localAsset != null && content.offlineAvailable
        ? DownloadState.bundled
        : DownloadState.notDownloaded,
  );
}
