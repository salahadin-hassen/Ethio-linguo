import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

// Provider-independent audio I/O used by the Speak feature for
// native-language voice (questions in, coaching out). Recordings live in
// memory only and are discarded after transcription.

abstract interface class VoiceRecorder {
  Future<bool> hasPermission();
  Future<void> start();

  /// Stops and returns a WAV clip (16 kHz mono), or null if nothing usable.
  Future<Uint8List?> stop();
  Future<void> cancel();
}

abstract interface class AudioClipPlayer {
  /// Plays a clip and completes when playback ends.
  Future<void> play(Uint8List bytes, {required String mimeType});
  Future<void> stop();
}

/// Records 16-bit PCM via the `record` plugin and wraps it as WAV.
class PcmVoiceRecorder implements VoiceRecorder {
  static const _rate = 16000;
  AudioRecorder? _rec;
  StreamSubscription<Uint8List>? _sub;
  final _buf = BytesBuilder(copy: false);

  AudioRecorder get _r => _rec ??= AudioRecorder();

  @override
  Future<bool> hasPermission() async {
    try {
      return await _r.hasPermission();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> start() async {
    _buf.clear();
    final stream = await _r.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _rate,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _sub = stream.listen(_buf.add);
  }

  @override
  Future<Uint8List?> stop() async {
    await _r.stop();
    await _sub?.cancel();
    _sub = null;
    final pcm = _buf.takeBytes();
    if (pcm.length < _rate) return null; // < 0.5 s of audio
    return wavFromPcm16(pcm, sampleRate: _rate);
  }

  @override
  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;
    _buf.clear();
    try {
      await _rec?.cancel();
    } catch (_) {}
  }
}

/// Minimal RIFF/WAV header around little-endian 16-bit mono PCM.
Uint8List wavFromPcm16(Uint8List pcm, {required int sampleRate}) {
  final h = ByteData(44);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      h.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  h.setUint32(4, 36 + pcm.length, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  h.setUint32(16, 16, Endian.little);
  h.setUint16(20, 1, Endian.little); // PCM
  h.setUint16(22, 1, Endian.little); // mono
  h.setUint32(24, sampleRate, Endian.little);
  h.setUint32(28, sampleRate * 2, Endian.little);
  h.setUint16(32, 2, Endian.little);
  h.setUint16(34, 16, Endian.little);
  str(36, 'data');
  h.setUint32(40, pcm.length, Endian.little);
  return (BytesBuilder()
        ..add(h.buffer.asUint8List())
        ..add(pcm))
      .takeBytes();
}

class PlatformAudioClipPlayer implements AudioClipPlayer {
  AudioPlayer? _p;

  @override
  Future<void> play(Uint8List bytes, {required String mimeType}) async {
    final p = _p ??= AudioPlayer();
    await p.stop();
    final done = p.onPlayerComplete.first;
    await p.play(BytesSource(bytes, mimeType: mimeType));
    await done.timeout(const Duration(seconds: 60), onTimeout: () {});
  }

  @override
  Future<void> stop() async {
    try {
      await _p?.stop();
    } catch (_) {}
  }
}

class UnavailableVoiceRecorder implements VoiceRecorder {
  const UnavailableVoiceRecorder();
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<void> start() async {}
  @override
  Future<Uint8List?> stop() async => null;
  @override
  Future<void> cancel() async {}
}

class SilentAudioClipPlayer implements AudioClipPlayer {
  const SilentAudioClipPlayer();
  @override
  Future<void> play(Uint8List bytes, {required String mimeType}) async {}
  @override
  Future<void> stop() async {}
}

bool get platformHasAudioIo =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
