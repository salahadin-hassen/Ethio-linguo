import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vocabulary.dart';

// SHARED CONTRACT (v2) — docs/INTEGRATION_CONTRACTS.md §5, §8.
// Writers: media_learning, tutor, revision. Readers: my_words, home.

/// My Words. Local storage is the source of truth; a future sync service
/// reads `dirty` entries and pushes them. Listenable so screens rebuild.
abstract class VocabularyRepository extends ChangeNotifier {
  /// Newest first.
  List<VocabularyEntry> get all;

  VocabularyEntry? byExpressionId(String expressionId);

  bool containsExpression(String expressionId) =>
      byExpressionId(expressionId) != null;

  List<VocabularyEntry> due(DateTime now) => [
    for (final e in all)
      if (e.isDue(now)) e,
  ];

  /// Inserts, or replaces the entry with the same id.
  Future<void> save(VocabularyEntry entry);

  Future<void> remove(String id);
}

/// Shared list-manipulation logic for both implementations.
mixin _ListStore on VocabularyRepository {
  List<VocabularyEntry> get items;
  set items(List<VocabularyEntry> v);
  Future<void> persist();

  @override
  List<VocabularyEntry> get all => List.unmodifiable(items);

  @override
  VocabularyEntry? byExpressionId(String expressionId) {
    for (final e in items) {
      if (e.expressionId == expressionId) return e;
    }
    return null;
  }

  @override
  Future<void> save(VocabularyEntry entry) {
    final i = items.indexWhere((e) => e.id == entry.id);
    items = i < 0 ? [entry, ...items] : ([...items]..[i] = entry);
    notifyListeners();
    return persist();
  }

  @override
  Future<void> remove(String id) {
    items = items.where((e) => e.id != id).toList();
    notifyListeners();
    return persist();
  }
}

class SharedPrefsVocabularyRepository extends VocabularyRepository
    with _ListStore {
  SharedPrefsVocabularyRepository._(this._prefs) {
    items = _read();
  }

  static const storageKey = 'vocabulary_entries_v2';
  final SharedPreferences _prefs;

  @override
  late List<VocabularyEntry> items;

  static Future<SharedPrefsVocabularyRepository> create() async =>
      SharedPrefsVocabularyRepository._(await SharedPreferences.getInstance());

  List<VocabularyEntry> _read() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          VocabularyEntry.fromJson((e as Map).cast<String, Object?>()),
      ];
    } catch (e) {
      debugPrint('vocabulary: corrupt store reset ($e)');
      return []; // Corrupt data must never brick the app.
    }
  }

  @override
  Future<void> persist() => _prefs.setString(
    storageKey,
    jsonEncode([for (final e in items) e.toJson()]),
  );
}

/// Volatile repository for tests and previews.
class InMemoryVocabularyRepository extends VocabularyRepository
    with _ListStore {
  InMemoryVocabularyRepository([List<VocabularyEntry>? initial])
    : items = [...?initial];

  @override
  List<VocabularyEntry> items;

  @override
  Future<void> persist() async {}
}
