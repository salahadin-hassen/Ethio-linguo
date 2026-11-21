import 'dart:io';

import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/features/lessons/lesson_complete_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import '../helpers/lesson_driver.dart';

/// Any attempt to open a network connection is recorded and refused.
class _NetworkTripwire extends HttpOverrides {
  final attempts = <String>[];

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts.add('HttpClient created');
    throw const SocketException('Network disabled in offline test');
  }
}

void main() {
  testWidgets('complete journey works with networking disabled', (t) async {
    final tripwire = _NetworkTripwire();
    final previous = HttpOverrides.current;
    HttpOverrides.global = tripwire;
    addTearDown(() => HttpOverrides.global = previous);

    await pumpApp(t);
    await t.tap(find.text('GET STARTED'));
    await t.pumpAndSettle();
    await t.tap(find.text('አማርኛ'));
    await t.pumpAndSettle();
    await t.tap(find.text('CONTINUE'));
    await t.pumpAndSettle();
    for (final tab in ['Learn', 'Discover', 'Speak', 'My Words', 'Home']) {
      await t.tap(find.byKey(ValueKey('nav_$tab')));
      await t.pumpAndSettle();
    }
    await t.tap(find.byKey(const ValueKey('continue_learning')));
    await t.pumpAndSettle();
    await playLesson(
      t,
      lessonExercises('l_greetings', NativeLanguage.amharic),
      wrongAt: {1},
    );
    expect(find.byType(LessonCompleteScreen), findsOneWidget);

    expect(
      tripwire.attempts,
      isEmpty,
      reason: 'the app must never touch the network',
    );
  });

  group('static offline guarantees', () {
    final libFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    // The ONLY network boundary is the optional AI tutor client.
    const onlineBoundary = 'lib/services/tutor/relay_tutor_engine.dart';

    test('network APIs exist only in the tutor boundary', () {
      final banned = RegExp(
        r'Image\.network|NetworkImage|HttpClient|package:http/|https?://|WebSocket',
      );
      final hits = [
        for (final f in libFiles)
          if (f.path.replaceAll(r'\', '/') != onlineBoundary)
            for (final (i, line) in f.readAsLinesSync().indexed)
              if (banned.hasMatch(line)) '${f.path}:${i + 1}: ${line.trim()}',
      ];
      expect(hits, isEmpty);
    });

    test('only approved dependencies (each with an offline story)', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final deps = RegExp(
        r'^dependencies:\n((?:  .*\n|\s*#.*\n|\n)*)',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1)!;
      final names = RegExp(
        r'^  (\w+):',
        multiLine: true,
      ).allMatches(deps).map((m) => m.group(1)).toSet();
      expect(names, {
        'flutter',
        'shared_preferences', // local persistence
        'video_player', // bundled asset playback
        'flutter_tts', // on-device speech output
        'speech_to_text', // OS speech recognition (tutor only)
        'http', // tutor relay client, isolated in onlineBoundary
        'record', // native-language questions to the tutor (online only)
        'audioplayers', // plays the Professor's native-language voice + SFX
        'rive', // rigged character runtime; .riv files are bundled locally
      });
    });

    test('app code that is not the tutor never imports the tutor client', () {
      final hits = [
        for (final f in libFiles)
          if (!f.path.endsWith('main.dart') &&
              f.readAsStringSync().contains('relay_tutor_engine.dart'))
            f.path,
      ];
      expect(hits, isEmpty);
    });

    test('all declared font assets are bundled locally', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final assets = RegExp(r'asset: (\S+)')
          .allMatches(pubspec)
          .map((m) => m.group(1)!)
          .toList();
      expect(assets, hasLength(9));
      for (final a in assets) {
        expect(File(a).existsSync(), isTrue, reason: a);
      }
    });
  });
}
