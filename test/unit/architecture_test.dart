import 'dart:io';

import 'package:ethio_linguo/data/repositories/content_repository.dart';
import 'package:ethio_linguo/data/repositories/conversation_repository.dart';
import 'package:ethio_linguo/data/repositories/vocabulary_repository.dart';
import 'package:ethio_linguo/services/speech/speech_services.dart';
import 'package:ethio_linguo/services/tutor/relay_tutor_engine.dart';
import 'package:ethio_linguo/services/tutor/tutor_engine.dart';
import 'package:flutter_test/flutter_test.dart';

// Lightweight architecture fitness tests (docs/ARCHITECTURE.md §Rules).

Iterable<File> dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

String norm(String p) => p.replaceAll(r'\', '/');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('implementations satisfy the shared interfaces', () {
    expect(BundledContentRepository(), isA<LearningContentRepository>());
    expect(BundledTranscriptRepository(), isA<TranscriptRepository>());
    expect(const BundledDownloadRepository(), isA<DownloadRepository>());
    expect(InMemoryVocabularyRepository(), isA<VocabularyRepository>());
    expect(InMemoryConversationRepository(), isA<ConversationRepository>());
    expect(RelayTutorEngine(Uri.parse('http://x')), isA<TutorEngine>());
    expect(const UnavailableTutorEngine(), isA<TutorEngine>());
    expect(PlatformSpeechRecognizer(), isA<SpeechRecognizer>());
    expect(PlatformSpeechSynthesizer(), isA<SpeechSynthesizer>());
  });

  test('features never import provider/plugin packages directly', () {
    final banned = RegExp(
      r"import 'package:(http|speech_to_text|flutter_tts|video_player)/",
    );
    final hits = [
      for (final f in dartFiles('lib/features'))
        if (banned.hasMatch(f.readAsStringSync())) norm(f.path),
    ];
    expect(hits, isEmpty, reason: 'go through lib/services interfaces');
  });

  test('features depend on tutor contracts, not a concrete provider', () {
    final hits = [
      for (final f in dartFiles('lib/features'))
        if (f.readAsStringSync().contains('relay_tutor_engine.dart'))
          norm(f.path),
    ];
    expect(hits, isEmpty);
  });

  test('domain models are not defined inside screens or widgets', () {
    final model = RegExp(
      r'^class (TranscriptSegment|Transcript|Expression|LearningContent|MediaItem|VocabularyEntry|TutorTurn|LearnerProfile)\b',
      multiLine: true,
    );
    final hits = [
      for (final f in dartFiles('lib/features'))
        if (model.hasMatch(f.readAsStringSync())) norm(f.path),
    ];
    expect(hits, isEmpty);
  });

  test('XP and streaks change only in the central progress service', () {
    final writes = RegExp(r'totalXp:\s|streak:\s|completedActivityIds:\s');
    final hits = [
      for (final f in dartFiles('lib'))
        if (!norm(f.path).endsWith('app/app_controller.dart') &&
            !norm(f.path).startsWith('lib/data/models/') &&
            writes.hasMatch(f.readAsStringSync()))
          norm(f.path),
    ];
    expect(hits, isEmpty);
  });

  test('no hard-coded secrets in app, relay or content', () {
    final secret = RegExp(
      r'sk-ant-[A-Za-z0-9_-]{8,}|sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{20,}|'
      r'''(api[_-]?key|secret|token)\s*[:=]\s*['"][A-Za-z0-9_\-]{16,}['"]''',
      caseSensitive: false,
    );
    final roots = ['lib', 'assets/content', 'server/src', 'android/app/src'];
    final hits = <String>[];
    for (final r in roots) {
      if (!Directory(r).existsSync()) continue;
      for (final f in Directory(
        r,
      ).listSync(recursive: true).whereType<File>()) {
        if (f.lengthSync() > 512 * 1024) continue; // binaries (video)
        String text;
        try {
          text = f.readAsStringSync();
        } catch (_) {
          continue;
        }
        if (secret.hasMatch(text)) hits.add(norm(f.path));
      }
    }
    expect(hits, isEmpty);
    expect(
      File('server/.env').existsSync() && _tracked('server/.env'),
      isFalse,
    );
  });

  test('UI support strings are centralised, not scattered in widgets', () {
    final ethiopic = RegExp(r'[ሀ-፿]');
    final allowed = {
      'lib/core/l10n/app_strings.dart',
      'lib/data/models/language.dart', // language names in their own script
      'lib/data/local/demo_course.dart', // legacy path-lesson content
      'lib/data/local/instructions.dart', // legacy path-lesson instructions
    };
    final hits = [
      for (final f in dartFiles('lib'))
        if (!allowed.contains(norm(f.path)) &&
            ethiopic.hasMatch(f.readAsStringSync()))
          norm(f.path),
    ];
    // Milestone-1 screens that predate the l10n layer are listed explicitly
    // so new code cannot add to the debt silently.
    expect(
      hits.toSet().difference({
        'lib/features/language_selection/language_selection_screen.dart',
        'lib/features/onboarding/welcome_screen.dart',
        'lib/features/home/widgets/home_header.dart',
        'lib/features/mascot/mascot.dart',
        'lib/features/lessons/widgets/feedback_panel.dart',
        'lib/features/lessons/logic/answer_validator.dart',
      }),
      isEmpty,
    );
  });
}

bool _tracked(String path) =>
    Process.runSync('git', ['ls-files', '--error-unmatch', path]).exitCode == 0;
