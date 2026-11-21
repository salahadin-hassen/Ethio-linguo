import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Product sound events. Short, quiet, original (tool/sfx/make_sfx.py).
/// Never required to understand anything: every sound has a visual twin.
enum Sfx { correct, incorrect, xp, save, complete, achievement, tap }

/// Sound effects with a persisted on/off preference.
abstract class SoundEffects extends ChangeNotifier {
  bool get enabled;
  Future<void> setEnabled(bool on);
  void play(Sfx s);
}

class SilentSoundEffects extends SoundEffects {
  final played = <Sfx>[];
  @override
  bool get enabled => true;
  @override
  Future<void> setEnabled(bool on) async {}
  @override
  void play(Sfx s) => played.add(s);
}

class AssetSoundEffects extends SoundEffects {
  AssetSoundEffects._(this._prefs) : _enabled = _prefs.getBool(_key) ?? true;

  static const _key = 'settings_sound_v1';
  final SharedPreferences _prefs;
  bool _enabled;
  final _players = <Sfx, AudioPlayer>{};

  static Future<AssetSoundEffects> create() async =>
      AssetSoundEffects._(await SharedPreferences.getInstance());

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool on) async {
    _enabled = on;
    notifyListeners();
    await _prefs.setBool(_key, on);
    if (on) play(Sfx.tap);
  }

  @override
  void play(Sfx s) {
    if (!_enabled) return;
    try {
      final p = _players[s] ??= AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setReleaseMode(ReleaseMode.stop);
      p.stop().then(
        (_) => p.play(AssetSource('sfx/${s.name}.wav'), volume: 0.6),
      );
    } catch (e) {
      debugPrint('sfx: $e'); // sound is optional; never break the flow
    }
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }
}
