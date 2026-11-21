import 'dart:io';

import 'package:ethio_linguo/core/navigation/app_routes.dart';
import 'package:ethio_linguo/data/models/content.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/data/repositories/vocabulary_repository.dart';
import 'package:ethio_linguo/services/analytics/analytics.dart';
import 'package:ethio_linguo/services/audio/sound_effects.dart';
import 'package:ethio_linguo/services/playback/media_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/harness.dart';

class _Tripwire extends HttpOverrides {
  final attempts = <String>[];
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts.add('HttpClient');
    throw const SocketException('offline test');
  }
}

/// The highest-risk journey (directive Part 5, items 1-15).
void main() {
  late ClockPlayback player;
  MediaPlayback factory(MediaItem m) => player = ClockPlayback(m.durationMs);

  Future<void> openLesson(WidgetTester t) async {
    await openRoute(
      t,
      AppRoutes.mediaLesson,
      arguments: const MediaLessonArgs('bus_stop_hello'),
    );
  }

  Future<void> seek(WidgetTester t, int ms) async {
    await player.seekTo(ms);
    await t.pump();
  }

  Text subtitle(WidgetTester t, String key) =>
      t.widget<Text>(find.byKey(ValueKey(key)));

  testWidgets('Amharic: offline scene -> subtitles -> expression -> save -> '
      'restart -> revision -> XP', (t) async {
    final tripwire = _Tripwire();
    final previous = HttpOverrides.current;
    HttpOverrides.global = tripwire;
    addTearDown(() => HttpOverrides.global = previous);

    SharedPreferences.setMockInitialValues({});
    final vocab = await t.runAsync(SharedPrefsVocabularyRepository.create);
    final analytics = RecordingAnalytics();
    final h = await pumpApp(
      t,
      progress: onboarded(),
      services: await warmServices(
        t,
        vocabulary: vocab,
        analytics: analytics,
        playbackFactory: factory,
      ),
    );

    // 4-5. Play bundled media; subtitles follow playback position.
    await openLesson(t);
    expect(find.text('Long time no see'), findsWidgets);
    await t.tap(find.byKey(const ValueKey('media_big_play')));
    player.advance(1000);
    await t.pump();
    expect(player.state.value.playing, isTrue);
    expect(find.textContaining('Hey, Dawit!'), findsWidgets);
    expect(subtitle(t, 'subtitle_native').data, 'ሄይ ዳዊት! ከተያየን ቆየን!');
    await seek(t, 5000);
    expect(subtitle(t, 'subtitle_native').data, contains('አንተስ?'));
    await seek(t, 2950); // gap between lines: no stale subtitle
    expect(find.byKey(const ValueKey('subtitle_native')), findsNothing);

    // 6-8. Select an expression -> contextual translation -> save.
    await seek(t, 1000);
    await t.tapOnText(find.textRange.ofSubstring('Long time no see').first);
    await t.pumpAndSettle();
    expect(player.state.value.playing, isFalse, reason: 'pauses to read');
    expect(find.byKey(const ValueKey('expression_sheet')), findsOneWidget);
    expect(subtitle(t, 'expression_meaning').data, 'ከተያየን ቆየን');
    expect(subtitle(t, 'expression_context').data, contains('ሊያ'));
    expect(find.text('Draft translation'), findsOneWidget);
    await t.ensureVisible(find.byKey(const ValueKey('expression_save')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('expression_save')));
    await t.pumpAndSettle();
    expect(find.text('SAVED TO MY WORDS'), findsOneWidget);
    expect(vocab!.containsExpression('long_time_no_see'), isTrue);
    // Feedback matches the real saved state: badge + count + sound.
    expect(
      find.byKey(const ValueKey('expression_saved_badge')),
      findsOneWidget,
    );
    expect(find.text('1 in My Words'), findsOneWidget);
    expect(
      (h.services.sounds as SilentSoundEffects).played,
      contains(Sfx.save),
    );
    expect(analytics.logged(AnalyticsEvent.vocabularySaved), isTrue);
    await t.tapAt(const Offset(10, 10)); // dismiss sheet
    await t.pumpAndSettle();

    // 12-13. Complete the lesson -> XP through the central service.
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('media_finish')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await t.tap(find.byKey(const ValueKey('media_finish')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('reward_sheet')), findsOneWidget);
    expect(find.text('Badge unlocked: Scene Starter'), findsOneWidget);
    expect(h.store.value!.totalXp, 15);
    expect(h.store.value!.completedActivityIds, {'media:bus_stop_hello'});
    await t.tap(find.byKey(const ValueKey('reward_done')));
    await t.pumpAndSettle();

    // 9-10. "Restart": a fresh repository reads the same device storage.
    final reopened = await t.runAsync(SharedPrefsVocabularyRepository.create);
    expect(reopened!.all.single.originalExpression, 'Long time no see');
    expect(reopened.all.single.contextLine, 'Hey, Dawit! Long time no see!');

    // My Words shows it; 11. revision completes and awards XP.
    await openRoute(t, AppRoutes.myWords);
    expect(
      find.byKey(const ValueKey('vocab_long_time_no_see')),
      findsOneWidget,
    );
    await t.tap(find.byKey(const ValueKey('my_words_review')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('revision_expression')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('revision_reveal')));
    await t.pumpAndSettle();
    expect(subtitle(t, 'revision_meaning').data, 'ከተያየን ቆየን');
    await t.tap(find.byKey(const ValueKey('revision_knew')));
    await t.pumpAndSettle();
    expect(find.text('Review complete!'), findsOneWidget);
    expect(h.store.value!.totalXp, 17); // 15 + 1 card x 2
    await t.tap(find.byKey(const ValueKey('reward_done')));
    await t.pumpAndSettle();

    // 14. None of the above touched the network.
    expect(tripwire.attempts, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets('Afaan Oromo learners see Oromo subtitles and explanations', (
    t,
  ) async {
    await pumpApp(
      t,
      progress: onboarded(native: NativeLanguage.oromo),
      services: await warmServices(t, playbackFactory: factory),
    );
    await openLesson(t);
    await seek(t, 3500);
    expect(subtitle(t, 'subtitle_native').data, 'Liyaa! Akkam turte?');
    await t.tapOnText(find.textRange.ofSubstring('How have you been?').first);
    await t.pumpAndSettle();
    expect(subtitle(t, 'expression_meaning').data, 'Akkam turte?');
    expect(find.textContaining('ሄይ'), findsNothing, reason: 'no Amharic leak');
  });

  testWidgets(
    'translation can be hidden; replay-line seeks to the line start',
    (t) async {
      await pumpApp(
        t,
        progress: onboarded(),
        services: await warmServices(t, playbackFactory: factory),
      );
      await openLesson(t);
      await seek(t, 8000);
      await t.tap(find.byKey(const ValueKey('media_toggle_translation')));
      await t.pump();
      expect(find.byKey(const ValueKey('subtitle_native')), findsNothing);
      await t.tap(find.byKey(const ValueKey('media_replay_line')));
      await t.pump();
      expect(player.state.value.positionMs, 7116); // start of s4
      expect(player.state.value.playing, isTrue);
      await t.pumpAndSettle();
    },
  );

  testWidgets('15. Speak without a tutor service: honest offline state', (
    t,
  ) async {
    await pumpApp(t, progress: onboarded());
    await tapTab(t, 'Speak');
    await t.tap(find.byKey(const ValueKey('speak_start')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('speak_unavailable')), findsOneWidget);
    expect(find.text('The Professor is offline right now'), findsOneWidget);
    expect(find.text('Offline practice (not AI)'), findsOneWidget);
    expect(find.byKey(const ValueKey('speak_feedback')), findsNothing);
  });

  testWidgets('Speak with a live tutor: scene context, transcript, feedback', (
    t,
  ) async {
    final tutor = FakeLiveTutor();
    final h = await pumpApp(
      t,
      progress: onboarded(),
      services: await warmServices(
        t,
        tutor: tutor,
        speechIn: FakeRecognizer(),
        speechOut: FakeSynth(),
        playbackFactory: factory,
      ),
    );
    await openLesson(t);
    await seek(t, 1000);
    await t.tapOnText(find.textRange.ofSubstring('Long time no see').first);
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const ValueKey('expression_practise')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('expression_practise')));
    await t.pumpAndSettle();
    expect(find.text('Roleplay "Long time no see"'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('speak_start')));
    await t.pumpAndSettle();
    expect(
      find.text(
        'Hey! Long time no see! How have you been?',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(tutor.requests.first.context.focusExpression, 'Long time no see');
    expect(tutor.requests.first.context.transcript, hasLength(6));

    // Live mode: the mic opened by itself after the opening line, heard the
    // learner, and the Professor answered with a task to do next.
    expect(
      find.text('Reply to: Long time no see', skipOffstage: false),
      findsOneWidget,
    );
    // Professor reflects the real verdict of the learner's last turn.
    expect(
      find.bySemanticsLabel(RegExp(r'The Professor, (approving|listening)')),
      findsWidgets,
    );
    expect(find.byKey(const ValueKey('speak_repeat_score')), findsOneWidget);
    expect(find.byKey(const ValueKey('speak_task')), findsOneWidget);
    expect(find.byKey(const ValueKey('speak_state_listening')), findsOneWidget);
    expect(find.byKey(const ValueKey('speak_feedback')), findsOneWidget);
    expect(find.textContaining('AI translation'), findsWidgets);
    expect(h.store.value!.totalXp, 0, reason: 'no XP for 1 turn');
  });
}
