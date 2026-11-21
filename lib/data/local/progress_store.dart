import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress.dart';

/// Persistence boundary for learner progress. The milestone uses a JSON blob
/// in SharedPreferences; a Drift/SQLite implementation can replace it later
/// without touching UI code.
abstract interface class ProgressStore {
  Future<LearnerProgress?> load();
  Future<void> save(LearnerProgress progress);
  Future<void> clear();
}

class SharedPrefsProgressStore implements ProgressStore {
  SharedPrefsProgressStore(this._prefs);

  static const _key = 'learner_progress_v1';
  final SharedPreferences _prefs;

  static Future<SharedPrefsProgressStore> create() async =>
      SharedPrefsProgressStore(await SharedPreferences.getInstance());

  @override
  Future<LearnerProgress?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return LearnerProgress.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      // Corrupt data must never brick the app; start fresh.
      return null;
    }
  }

  @override
  Future<void> save(LearnerProgress progress) =>
      _prefs.setString(_key, jsonEncode(progress.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}

/// Volatile store for tests and previews.
class InMemoryProgressStore implements ProgressStore {
  InMemoryProgressStore([this.value]);

  LearnerProgress? value;
  int saves = 0;

  @override
  Future<LearnerProgress?> load() async => value;

  @override
  Future<void> save(LearnerProgress progress) async {
    value = progress;
    saves++;
  }

  @override
  Future<void> clear() async => value = null;
}
