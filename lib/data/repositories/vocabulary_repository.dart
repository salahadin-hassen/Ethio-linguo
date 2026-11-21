import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_expression.dart';

// SHARED CONTRACT — see docs/INTEGRATION_CONTRACTS.md §5 and §8.
// Writers: media_lesson (Engineer 2), speak (Engineer 3).
// Readers: my_words, home (Engineer 1).

/// My Words storage. Listenable so any screen can rebuild when a word is
/// saved elsewhere. Everything is local; there is no sync in the MVP.
abstract class VocabularyRepository extends ChangeNotifier {
  /// Newest first.
  List<SavedExpression> get all;

  bool contains(String id);

  /// Saves or replaces by id.
  Future<void> save(SavedExpression e);

  Future<void> remove(String id);

  Future<void> markReviewed(String id);
}

class SharedPrefsVocabularyRepository extends VocabularyRepository {
  SharedPrefsVocabularyRepository._(this._prefs) {
    _items = _read();
  }

  static const storageKey = 'saved_expressions_v1';
  final SharedPreferences _prefs;
  late List<SavedExpression> _items;

  static Future<SharedPrefsVocabularyRepository> create() async =>
      SharedPrefsVocabularyRepository._(await SharedPreferences.getInstance());

  List<SavedExpression> _read() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          SavedExpression.fromJson((e as Map).cast<String, Object?>()),
      ];
    } catch (_) {
      return []; // Corrupt data must never brick the app.
    }
  }

  Future<void> _write() async {
    notifyListeners();
    await _prefs.setString(
      storageKey,
      jsonEncode([for (final e in _items) e.toJson()]),
    );
  }

  @override
  List<SavedExpression> get all => List.unmodifiable(_items);

  @override
  bool contains(String id) => _items.any((e) => e.id == id);

  @override
  Future<void> save(SavedExpression e) {
    _items = [e, ..._items.where((x) => x.id != e.id)];
    return _write();
  }

  @override
  Future<void> remove(String id) {
    _items = _items.where((x) => x.id != id).toList();
    return _write();
  }

  @override
  Future<void> markReviewed(String id) {
    _items = [
      for (final x in _items)
        x.id == id ? x.copyWith(reviewCount: x.reviewCount + 1) : x,
    ];
    return _write();
  }
}

/// Volatile repository for tests and previews.
class InMemoryVocabularyRepository extends VocabularyRepository {
  InMemoryVocabularyRepository([List<SavedExpression>? initial])
    : _items = [...?initial];

  List<SavedExpression> _items;

  @override
  List<SavedExpression> get all => List.unmodifiable(_items);

  @override
  bool contains(String id) => _items.any((e) => e.id == id);

  @override
  Future<void> save(SavedExpression e) async {
    _items = [e, ..._items.where((x) => x.id != e.id)];
    notifyListeners();
  }

  @override
  Future<void> remove(String id) async {
    _items = _items.where((x) => x.id != id).toList();
    notifyListeners();
  }

  @override
  Future<void> markReviewed(String id) async {
    _items = [
      for (final x in _items)
        x.id == id ? x.copyWith(reviewCount: x.reviewCount + 1) : x,
    ];
    notifyListeners();
  }
}
