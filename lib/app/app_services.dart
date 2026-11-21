import 'package:flutter/widgets.dart';

import '../data/models/content.dart';
import '../data/repositories/content_repository.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/repositories/vocabulary_repository.dart';
import '../services/analytics/analytics.dart';
import '../services/audio/audio_services.dart';
import '../services/playback/media_playback.dart';
import '../services/speech/speech_services.dart';
import '../services/tutor/explanation_provider.dart';
import '../services/tutor/tutor_engine.dart';

/// Composition root for replaceable boundaries (repositories, providers).
/// Built once in main.dart; tests pass fakes. Features depend on these
/// interfaces only — never on a plugin or AI provider directly.
class AppServices {
  AppServices({
    required this.content,
    required this.transcripts,
    required this.downloads,
    required this.vocabulary,
    required this.conversations,
    required this.tutor,
    required this.speechIn,
    required this.speechOut,
    required this.explanations,
    required this.playbackFactory,
    required this.analytics,
    this.nativeVoice = const UnavailableNativeVoice(),
    this.recorder = const UnavailableVoiceRecorder(),
    this.clipPlayer = const SilentAudioClipPlayer(),
  });

  /// Offline-safe defaults for tests and previews: no plugins, no network.
  factory AppServices.inMemory({
    LearningContentRepository? content,
    TranscriptRepository? transcripts,
    VocabularyRepository? vocabulary,
    TutorEngine? tutor,
    SpeechRecognizer? speechIn,
    SpeechSynthesizer? speechOut,
    MediaPlaybackFactory? playbackFactory,
    Analytics? analytics,
    NativeVoice? nativeVoice,
    VoiceRecorder? recorder,
    AudioClipPlayer? clipPlayer,
  }) => AppServices(
    nativeVoice: nativeVoice ?? const UnavailableNativeVoice(),
    recorder: recorder ?? const UnavailableVoiceRecorder(),
    clipPlayer: clipPlayer ?? const SilentAudioClipPlayer(),
    content: content ?? BundledContentRepository(),
    transcripts: transcripts ?? BundledTranscriptRepository(),
    downloads: const BundledDownloadRepository(),
    vocabulary: vocabulary ?? InMemoryVocabularyRepository(),
    conversations: InMemoryConversationRepository(),
    tutor: tutor ?? const UnavailableTutorEngine(),
    speechIn: speechIn ?? const UnavailableSpeechRecognizer(),
    speechOut: speechOut ?? const UnavailableSpeechSynthesizer(),
    explanations: const BundledExplanationProvider(),
    playbackFactory:
        playbackFactory ?? (MediaItem m) => ClockPlayback(m.durationMs),
    analytics: analytics ?? const DebugAnalytics(),
  );

  final LearningContentRepository content;
  final TranscriptRepository transcripts;
  final DownloadRepository downloads;
  final VocabularyRepository vocabulary;
  final ConversationRepository conversations;
  final TutorEngine tutor;
  final SpeechRecognizer speechIn;
  final SpeechSynthesizer speechOut;
  final ExplanationProvider explanations;
  final MediaPlaybackFactory playbackFactory;
  final Analytics analytics;

  /// Amharic / Afaan Oromo voice for the Professor (speak + transcribe).
  final NativeVoice nativeVoice;
  final VoiceRecorder recorder;
  final AudioClipPlayer clipPlayer;
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ServicesScope>()!.services;

  @override
  bool updateShouldNotify(ServicesScope old) => old.services != services;
}
