import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/content.dart';

/// Snapshot of a player. Immutable so listeners can diff cheaply.
@immutable
class PlaybackState {
  const PlaybackState({
    this.ready = false,
    this.playing = false,
    this.positionMs = 0,
    this.durationMs = 0,
    this.completed = false,
    this.error,
  });

  final bool ready;
  final bool playing;
  final int positionMs;
  final int durationMs;
  final bool completed;
  final String? error;

  PlaybackState copyWith({
    bool? ready,
    bool? playing,
    int? positionMs,
    int? durationMs,
    bool? completed,
    String? error,
  }) => PlaybackState(
    ready: ready ?? this.ready,
    playing: playing ?? this.playing,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    completed: completed ?? this.completed,
    error: error ?? this.error,
  );
}

/// Player abstraction used by every timed-content reader (video now; songs,
/// audio stories, podcasts later). Owners MUST call [dispose].
abstract class MediaPlayback {
  ValueListenable<PlaybackState> get state;
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(int ms);

  /// The visual surface, or null for audio-only / no-video fallback.
  Widget? buildView();
  Future<void> dispose();
}

typedef MediaPlaybackFactory = MediaPlayback Function(MediaItem media);

/// Bundled video via the official video_player plugin (Android, iOS, web).
class VideoPlayerPlayback extends MediaPlayback {
  VideoPlayerPlayback(this.media);

  final MediaItem media;
  late final VideoPlayerController _c = VideoPlayerController.asset(
    media.localAsset!,
  );
  final _state = ValueNotifier(const PlaybackState());
  bool _disposed = false;

  @override
  ValueListenable<PlaybackState> get state => _state;

  void _sync() {
    if (_disposed) return;
    final v = _c.value;
    final pos = v.position.inMilliseconds;
    final dur = v.duration.inMilliseconds;
    _state.value = PlaybackState(
      ready: v.isInitialized,
      playing: v.isPlaying,
      positionMs: pos,
      durationMs: dur,
      completed: v.isInitialized && dur > 0 && pos >= dur - 50 && !v.isPlaying,
      error: v.hasError ? (v.errorDescription ?? 'Playback error') : null,
    );
  }

  @override
  Future<void> initialize() async {
    _c.addListener(_sync);
    try {
      await _c.initialize();
    } catch (e) {
      _state.value = PlaybackState(error: 'Video could not be opened ($e)');
      return;
    }
    _sync();
  }

  @override
  Future<void> play() async {
    if (_state.value.completed) await _c.seekTo(Duration.zero);
    await _c.play();
  }

  @override
  Future<void> pause() => _c.pause();

  @override
  Future<void> seekTo(int ms) => _c.seekTo(Duration(milliseconds: ms));

  @override
  Widget? buildView() => _state.value.ready
      ? AspectRatio(aspectRatio: _c.value.aspectRatio, child: VideoPlayer(_c))
      : null;

  @override
  Future<void> dispose() async {
    _disposed = true;
    _c.removeListener(_sync);
    await _c.dispose();
    _state.dispose();
  }
}

/// A clock-driven player with no picture. Used in tests, and on platforms
/// without a video plugin (Linux desktop) where the UI says so explicitly.
class ClockPlayback extends MediaPlayback {
  ClockPlayback(
    this.durationMs, {
    this.tick = const Duration(milliseconds: 100),
  });

  final int durationMs;
  final Duration tick;
  final _state = ValueNotifier(const PlaybackState());
  Timer? _timer;

  @override
  ValueListenable<PlaybackState> get state => _state;

  @override
  Future<void> initialize() async =>
      _state.value = PlaybackState(ready: true, durationMs: durationMs);

  @override
  Future<void> play() async {
    if (_state.value.completed) await seekTo(0);
    _timer?.cancel();
    _state.value = _state.value.copyWith(playing: true, completed: false);
    _timer = Timer.periodic(tick, (_) => advance(tick.inMilliseconds));
  }

  /// Moves the clock (tests call this directly).
  void advance(int ms) {
    final pos = (_state.value.positionMs + ms).clamp(0, durationMs);
    final done = pos >= durationMs;
    if (done) _timer?.cancel();
    _state.value = _state.value.copyWith(
      positionMs: pos,
      playing: !done && _state.value.playing,
      completed: done,
    );
  }

  @override
  Future<void> pause() async {
    _timer?.cancel();
    _state.value = _state.value.copyWith(playing: false);
  }

  @override
  Future<void> seekTo(int ms) async => _state.value = _state.value.copyWith(
    positionMs: ms.clamp(0, durationMs),
    completed: false,
  );

  @override
  Widget? buildView() => null;

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _state.dispose();
  }
}

/// video_player has no Linux/Windows desktop implementation.
bool get platformHasVideo =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

MediaPlayback defaultPlaybackFactory(MediaItem media) =>
    platformHasVideo && media.localAsset != null
    ? VideoPlayerPlayback(media)
    : ClockPlayback(media.durationMs);
