import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_controller.dart';
import 'app/app_services.dart';
import 'data/local/demo_course.dart';
import 'data/local/progress_store.dart';
import 'data/repositories/content_repository.dart';
import 'data/repositories/conversation_repository.dart';
import 'data/repositories/vocabulary_repository.dart';
import 'services/analytics/analytics.dart';
import 'services/audio/audio_services.dart';
import 'services/playback/media_playback.dart';
import 'services/speech/speech_services.dart';
import 'services/tutor/explanation_provider.dart';
import 'services/tutor/relay_tutor_engine.dart';
import 'services/tutor/tutor_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Everything below is local: bundled course content + on-device progress.
  final store = await SharedPrefsProgressStore.create();
  final controller = await AppController.load(
    course: DemoCourse.course,
    store: store,
  );
  // Replaceable boundaries. Core learning is local; only the tutor relay
  // is network-bound and is configured at build time:
  //   flutter run --dart-define=TUTOR_BASE_URL=<relay base url>
  const relay = String.fromEnvironment('TUTOR_BASE_URL');
  final services = AppServices(
    content: BundledContentRepository(),
    transcripts: BundledTranscriptRepository(),
    downloads: const BundledDownloadRepository(),
    vocabulary: await SharedPrefsVocabularyRepository.create(),
    conversations: InMemoryConversationRepository(),
    tutor: relay.isEmpty
        ? const UnavailableTutorEngine(
            'No tutor service is configured in this build.',
          )
        : RelayTutorEngine(Uri.parse(relay)),
    speechIn: PlatformSpeechRecognizer(),
    speechOut: PlatformSpeechSynthesizer(),
    explanations: const BundledExplanationProvider(),
    playbackFactory: defaultPlaybackFactory,
    analytics: const DebugAnalytics(),
    nativeVoice: relay.isEmpty
        ? const UnavailableNativeVoice()
        : RelayNativeVoice(Uri.parse(relay)),
    recorder: platformHasAudioIo
        ? PcmVoiceRecorder()
        : const UnavailableVoiceRecorder(),
    clipPlayer: platformHasAudioIo
        ? PlatformAudioClipPlayer()
        : const SilentAudioClipPlayer(),
  );
  runApp(LearningApp(controller: controller, services: services));
}
