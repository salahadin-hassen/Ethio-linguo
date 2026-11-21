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
    for (final tab in ['Path', 'Garden', 'Badges', 'Home']) {
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

    test('no network APIs or remote URLs in app code', () {
      final banned = RegExp(
        r'Image\.network|NetworkImage|HttpClient|package:http/|https?://|WebSocket',
      );
      final hits = [
        for (final f in libFiles)
          for (final (i, line) in f.readAsLinesSync().indexed)
            if (banned.hasMatch(line)) '${f.path}:${i + 1}: ${line.trim()}',
      ];
      expect(hits, isEmpty);
    });

    test('only offline-capable dependencies', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final deps = RegExp(
        r'^dependencies:\n((?:  .*\n|\s*#.*\n|\n)*)',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1)!;
      final names = RegExp(
        r'^  (\w+):',
        multiLine: true,
      ).allMatches(deps).map((m) => m.group(1)).toSet();
      expect(names, {'flutter', 'shared_preferences'});
    });

    test('release Android manifest requests no INTERNET permission', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest.contains('android.permission.INTERNET'), isFalse);
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
