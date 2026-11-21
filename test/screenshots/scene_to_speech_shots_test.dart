// Screens of the Scene-to-Speech MVP, rendered with real fonts and the real
// bundled content. Run: flutter test test/screenshots --run-skipped --update-goldens
@Tags(['screenshots'])
library;

import 'package:ethio_linguo/core/navigation/app_routes.dart';
import 'package:ethio_linguo/data/models/content.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/services/playback/media_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/fonts.dart';
import '../helpers/harness.dart';

Future<void> shot(WidgetTester t, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$name.png'));

Future<void> precachePoster(WidgetTester t) async {
  await t.runAsync(() async {
    final ctx = t.element(find.byType(Navigator).first);
    await precacheImage(
      const AssetImage('assets/content/bus_stop_hello/poster.jpg'),
      ctx,
    );
  });
  await t.pump();
}

void main() {
  setUpAll(loadAppFonts);
  late ClockPlayback player;
  MediaPlayback factory(MediaItem m) => player = ClockPlayback(m.durationMs);

  Future<void> lesson(WidgetTester t, NativeLanguage lang, int ms) async {
    await pumpApp(
      t,
      progress: onboarded(native: lang),
      services: await warmServices(t, playbackFactory: factory),
    );
    await precachePoster(t);
    await openRoute(
      t,
      AppRoutes.mediaLesson,
      arguments: const MediaLessonArgs('bus_stop_hello'),
    );
    await player.seekTo(ms);
    await t.pumpAndSettle();
  }

  testWidgets('30 home with scene + entry points', (t) async {
    await pumpApp(t, progress: midJourney(), services: await warmServices(t));
    await precachePoster(t);
    await t.pumpAndSettle();
    await t.drag(find.byType(CustomScrollView).first, const Offset(0, -260));
    await t.pumpAndSettle();
    await shot(t, '30_home_scene_entry_points');
  });

  testWidgets('31 discover', (t) async {
    await pumpApp(t, progress: onboarded(), services: await warmServices(t));
    await precachePoster(t);
    await tapTab(t, 'Discover');
    await shot(t, '31_discover');
  });

  testWidgets('32-33 media lesson am / om', (t) async {
    await lesson(t, NativeLanguage.amharic, 1200);
    await shot(t, '32_media_lesson_amharic');
  });

  testWidgets('33 media lesson om', (t) async {
    await lesson(t, NativeLanguage.oromo, 11000);
    await shot(t, '33_media_lesson_oromo');
  });

  testWidgets('34 expression sheet', (t) async {
    await lesson(t, NativeLanguage.amharic, 1200);
    await t.tapOnText(find.textRange.ofSubstring('Long time no see').first);
    await t.pumpAndSettle();
    await shot(t, '34_expression_sheet');
  });

  testWidgets('35 my words + 36 revision', (t) async {
    await lesson(t, NativeLanguage.amharic, 1200);
    for (final (phrase, ms) in [
      ('Long time no see', 1200),
      ('catch up', 11000),
    ]) {
      await player.seekTo(ms);
      await t.pumpAndSettle();
      await t.tapOnText(find.textRange.ofSubstring(phrase).first);
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('expression_save')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('expression_save')));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
    }
    await openRoute(t, AppRoutes.myWords);
    await shot(t, '35_my_words');
    await t.tap(find.byKey(const ValueKey('my_words_review')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('revision_reveal')));
    await t.pumpAndSettle();
    await shot(t, '36_revision');
  });

  testWidgets('37 professor offline', (t) async {
    await pumpApp(t, progress: onboarded(), services: await warmServices(t));
    await tapTab(t, 'Speak');
    await t.tap(find.byKey(const ValueKey('speak_start')));
    await t.pumpAndSettle();
    await shot(t, '37_professor_offline');
  });

  testWidgets('38 professor conversation (test double, not live AI)', (
    t,
  ) async {
    final tutor = FakeLiveTutor();
    final services = await warmServices(
      t,
      tutor: tutor,
      speechIn: FakeRecognizer(say: 'I been busy with my new job'),
      speechOut: FakeSynth(),
      playbackFactory: factory,
    );
    await pumpApp(t, progress: onboarded(), services: services);
    await precachePoster(t);
    await openRoute(
      t,
      AppRoutes.mediaLesson,
      arguments: const MediaLessonArgs('bus_stop_hello'),
    );
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('media_finish')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await t.ensureVisible(find.byKey(const ValueKey('media_finish')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('media_finish')));
    await t.pumpAndSettle();
    await shot(t, '38_scene_complete_reward');
    await t.tap(find.byKey(const ValueKey('reward_primary')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('speak_start')));
    await t.pumpAndSettle();
    await t.longPress(find.byKey(const ValueKey('speak_talk')));
    await t.pumpAndSettle();
    await shot(t, '39_professor_session_ui');
  });
}
