import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

// Provider-independent speech contracts. The Speak feature depends only on
// these; on-device platform engines are the MVP implementations. Audio is
// never recorded to disk or uploaded by the app — recognition happens in the
// OS speech service and only text leaves this layer.

class RecognizedSpeech {
  const RecognizedSpeech(this.text, {this.confidence, required this.isFinal});
  final String text;
  final double? confidence;
  final bool isFinal;
}

abstract interface class SpeechRecognizer {
  /// Asks for microphone permission on first call. False = unavailable.
  Future<bool> initialize();
  bool get available;

  /// Streams partial and final results until [stop] or a pause.
  /// [onLevel] receives the REAL input level (0..1) when the platform
  /// reports one; it is never synthesised.
  Future<void> listen({
    required String localeId,
    required void Function(RecognizedSpeech) onResult,
    void Function(double level)? onLevel,
  });
  Future<void> stop();
  Future<void> cancel();
}

abstract interface class SpeechSynthesizer {
  Future<bool> initialize();
  bool get available;

  /// Completes when speaking ends (or immediately if unavailable).
  Future<void> speak(String text, {required String localeId});
  Future<void> stop();
}

/// Android/iOS/web speech recognition (speech_to_text).
class PlatformSpeechRecognizer implements SpeechRecognizer {
  late final SpeechToText _stt = SpeechToText();
  bool _ok = false;
  String? lastError;

  @override
  bool get available => _ok;

  @override
  Future<bool> initialize() async {
    if (!_supported) return false;
    try {
      _ok = await _stt.initialize(onError: (e) => lastError = e.errorMsg);
    } catch (e) {
      lastError = '$e';
      _ok = false;
    }
    return _ok;
  }

  @override
  Future<void> listen({
    required String localeId,
    required void Function(RecognizedSpeech) onResult,
    void Function(double level)? onLevel,
  }) => _stt.listen(
    // Platform levels are roughly -2..10 dB; normalise to 0..1.
    onSoundLevelChange: onLevel == null
        ? null
        : (db) => onLevel(((db + 2) / 12).clamp(0.0, 1.0)),
    onResult: (SpeechRecognitionResult r) => onResult(
      RecognizedSpeech(
        r.recognizedWords,
        confidence: r.hasConfidenceRating ? r.confidence : null,
        isFinal: r.finalResult,
      ),
    ),
    listenOptions: SpeechListenOptions(
      localeId: localeId,
      partialResults: true,
      cancelOnError: true,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    ),
  );

  @override
  Future<void> stop() => _stt.stop();

  @override
  Future<void> cancel() => _stt.cancel();
}

/// Android/iOS/web text-to-speech (flutter_tts).
class PlatformSpeechSynthesizer implements SpeechSynthesizer {
  // Created lazily: no platform channel is opened until speech is needed.
  late final FlutterTts _tts = FlutterTts();
  bool _ok = false;

  @override
  bool get available => _ok;

  @override
  Future<bool> initialize() async {
    if (!_supported) return false;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
      _ok = true;
    } catch (_) {
      _ok = false;
    }
    return _ok;
  }

  @override
  Future<void> speak(String text, {required String localeId}) async {
    if (!_ok) return;
    await _tts.setLanguage(localeId);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    if (_ok) await _tts.stop();
  }
}

/// Neither plugin supports Linux desktop.
bool get _supported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Explicitly unavailable implementations (tests, unsupported platforms).
class UnavailableSpeechRecognizer implements SpeechRecognizer {
  const UnavailableSpeechRecognizer();
  @override
  bool get available => false;
  @override
  Future<bool> initialize() async => false;
  @override
  Future<void> listen({
    required String localeId,
    required void Function(RecognizedSpeech) onResult,
    void Function(double level)? onLevel,
  }) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> cancel() async {}
}

class UnavailableSpeechSynthesizer implements SpeechSynthesizer {
  const UnavailableSpeechSynthesizer();
  @override
  bool get available => false;
  @override
  Future<bool> initialize() async => false;
  @override
  Future<void> speak(String text, {required String localeId}) async {}
  @override
  Future<void> stop() async {}
}
