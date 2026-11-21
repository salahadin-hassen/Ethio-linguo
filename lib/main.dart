import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/tutor/relay_endpoint.dart';

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
import 'services/audio/sound_effects.dart';
import 'services/playback/media_playback.dart';
import 'services/speech/speech_services.dart';
import 'services/tutor/explanation_provider.dart';
import 'services/tutor/relay_tutor_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Everything below is local: bundled course content + on-device progress.
  final store = await SharedPrefsProgressStore.create();
  final controller = await AppController.load(
    course: DemoCourse.course,
    store: store,
  );
  // Replaceable boundaries. Core learning is local; only the tutor relay
  // is network-bound. Its address comes from the build
  //   flutter run --dart-define=TUTOR_BASE_URL=<relay base url>
  // and can be changed on the device (saved), e.g. when the demo laptop's
  // Wi-Fi address changes.
  const builtIn = String.fromEnvironment('TUTOR_BASE_URL');
  final prefs = await SharedPreferences.getInstance();
  const relayKey = 'tutor_relay_url';
  final relay = RelayEndpoint(
    RelayEndpoint.parse(prefs.getString(relayKey) ?? builtIn),
    onSave: (u) async {
      if (u == null) {
        await prefs.remove(relayKey);
      } else {
        await prefs.setString(relayKey, u.toString());
      }
    },
  );
  final services = AppServices(
    content: BundledContentRepository(),
    transcripts: BundledTranscriptRepository(),
    downloads: const BundledDownloadRepository(),
    vocabulary: await SharedPrefsVocabularyRepository.create(),
    conversations: InMemoryConversationRepository(),
    tutor: RelayTutorEngine.at(relay),
    relay: relay,
    speechIn: PlatformSpeechRecognizer(),
    speechOut: PlatformSpeechSynthesizer(),
    explanations: const BundledExplanationProvider(),
    playbackFactory: defaultPlaybackFactory,
    analytics: const DebugAnalytics(),
    nativeVoice: RelayNativeVoice.at(relay),
    recorder: platformHasAudioIo
        ? PcmVoiceRecorder()
        : const UnavailableVoiceRecorder(),
    sounds: await AssetSoundEffects.create(),
    clipPlayer: platformHasAudioIo
        ? PlatformAudioClipPlayer()
        : const SilentAudioClipPlayer(),
  );
  runApp(LearningApp(controller: controller, services: services));
}
