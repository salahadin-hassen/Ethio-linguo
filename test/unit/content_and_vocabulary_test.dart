import 'dart:convert';
import 'dart:io';

import 'package:ethio_linguo/app/app_controller.dart';
import 'package:ethio_linguo/data/local/demo_course.dart';
import 'package:ethio_linguo/data/local/progress_store.dart';
import 'package:ethio_linguo/data/models/activity.dart';
import 'package:ethio_linguo/data/models/content.dart';
import 'package:ethio_linguo/data/models/conversation.dart';
import 'package:ethio_linguo/data/models/gamification.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/data/models/progress.dart';
import 'package:ethio_linguo/data/models/transcript.dart';
import 'package:ethio_linguo/data/models/vocabulary.dart';
import 'package:ethio_linguo/data/repositories/content_repository.dart';
import 'package:ethio_linguo/data/repositories/vocabulary_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves files from disk (so these tests read the REAL bundled content).
class DiskBundle extends CachingAssetBundle {
  DiskBundle([this.overrides = const {}]);
  final Map<String, String> overrides;

  @override
  Future<ByteData> load(String key) async {
    final text = overrides[key];
    final bytes = text != null
        ? utf8.encode(text)
        : await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

const codes = ['am', 'om'];

void main() {
  late LearningContent content;
  late Transcript transcript;

  setUpAll(() async {
    final repo = BundledContentRepository(bundle: DiskBundle());
    final all = await repo.list();
    content = all.firstWhere((c) => c.id == 'bus_stop_hello');
    transcript = await BundledTranscriptRepository(bundle: DiskBundle())
        .load(content, languages: codes);
  });

  group('bundled content package', () {
    test('manifest is valid, rights-cleared and offline-usable', () {
      expect(content.id, 'bus_stop_hello');
      expect(content.type, ContentType.video);
      expect(content.rights.offlineUseAllowed, isTrue);
      expect(content.rights.derivativeTranslationsAllowed, isTrue);
      expect(content.rights.licenseType, 'original');
      expect(File(content.media.localAsset!).existsSync(), isTrue);
      expect(File(content.media.localAsset!).lengthSync(), lessThan(10 << 20));
    });

    test('every segment and expression is translated to am and om', () {
      expect(transcript.segments, hasLength(6));
      for (final s in transcript.segments) {
        for (final c in codes) {
          expect(s.translations[c], isNotEmpty, reason: '${s.id} $c');
        }
      }
      for (final e in transcript.expressions) {
        for (final c in codes) {
          expect(e.meaning[c], isNotEmpty, reason: '${e.id} meaning $c');
          expect(e.contextualMeaning[c], isNotEmpty, reason: '${e.id} ctx $c');
        }
      }
    });

    test(
      'translations are honestly labelled: reviewed requires a reviewer',
      () {
        for (final info in content.translations.values) {
          if (info.isReviewed) expect(info.reviewer, isNotEmpty);
        }
        // Today both are drafts awaiting native-speaker review.
        expect(content.translations.values.every((t) => !t.isReviewed), isTrue);
      },
    );

    test('content with offline use forbidden is not listed', () async {
      final manifest = File('assets/content/bus_stop_hello/manifest.json')
          .readAsStringSync()
          .replaceFirst(
            '"offlineUseAllowed": true',
            '"offlineUseAllowed": false',
          );
      final repo = BundledContentRepository(
        bundle: DiskBundle({
          'assets/content/bus_stop_hello/manifest.json': manifest,
        }),
      );
      expect(
        (await repo.list()).map((c) => c.id),
        isNot(contains('bus_stop_hello')),
      );
    });
  });

  group('transcript sync (pure logic, no widgets)', () {
    test('segmentAt finds the line on screen at each timestamp', () {
      expect(transcript.segmentAt(0), isNull); // before first line
      expect(transcript.segmentAt(600)!.id, 's1');
      expect(transcript.segmentAt(2896)!.id, 's1');
      expect(transcript.segmentAt(2897), isNull); // gap, end exclusive
      expect(transcript.segmentAt(5000)!.id, 's3');
      expect(transcript.segmentAt(14782)!.id, 's6');
      expect(transcript.segmentAt(20000), isNull);
      expect(transcript.segmentAtOrBefore(2950)!.id, 's1');
    });

    test('expressions are located inside their segments for highlighting', () {
      final s6 = transcript.segmentById('s6')!;
      final spans = spansFor(s6.originalText, transcript.expressionsIn(s6));
      expect(spans.map((s) => s.text).join(), s6.originalText);
      expect(
        [
          for (final s in spans)
            if (s.expression != null) s.text,
        ],
        ['Sounds good', 'See you soon'],
      );
    });

    test('overlapping or misplaced data is rejected', () {
      expect(
        () => Transcript(
          mediaId: 'm',
          language: 'en',
          segments: const [
            TranscriptSegment(
              id: 'a',
              mediaId: 'm',
              startMs: 0,
              endMs: 100,
              originalText: 'x',
            ),
            TranscriptSegment(
              id: 'b',
              mediaId: 'm',
              startMs: 50,
              endMs: 200,
              originalText: 'y',
            ),
          ],
          expressions: const [],
        ),
        throwsFormatException,
      );
    });
  });

  group('repeat scoring', () {
    test('word-level match with contractions and punctuation', () {
      final s = scoreRepeat(
        "I've been busy with my new job.",
        'i have been busy with my job',
      );
      expect(s.missing, ['new']);
      expect(s.matched, 6);
      expect(s.passed, isTrue); // 6/7 >= 80%
      expect(scoreRepeat('Long time no see!', 'long time').passed, isFalse);
      expect(
        scoreRepeat('Long time no see!', 'long time no see').passed,
        isTrue,
      );
    });
  });

  group('vocabulary', () {
    VocabularyEntry entry() => VocabularyEntry.fromExpression(
      id: 'id-1',
      learnerId: 'learner',
      content: content,
      segment: transcript.segmentById('s1')!,
      expression: transcript.expression('long_time_no_see')!,
      now: DateTime.utc(2026, 11, 21, 9),
    );

    test('entry keeps context, source and translations; JSON round-trips', () {
      final e = entry();
      expect(e.contextLine, 'Hey, Dawit! Long time no see!');
      expect(e.sourceContentId, 'bus_stop_hello');
      expect(e.meaningIn(NativeLanguage.amharic), 'ከተያየን ቆየን');
      final back = VocabularyEntry.fromJson(
        jsonDecode(jsonEncode(e.toJson())) as Map<String, Object?>,
      );
      expect(back.toJson(), e.toJson());
    });

    test('simple fixed-interval review schedule', () {
      final now = DateTime.utc(2026, 11, 21, 9);
      var e = entry();
      expect(e.isDue(now), isTrue);
      e = e.reviewed(remembered: true, now: now);
      expect(e.masteryStatus, MasteryStatus.familiar);
      expect(e.nextReviewAt, now.add(const Duration(days: 3)));
      e = e.reviewed(remembered: true, now: now);
      expect(e.masteryStatus, MasteryStatus.mastered);
      e = e.reviewed(remembered: false, now: now);
      expect(e.masteryStatus, MasteryStatus.learning);
      expect(e.reviewCount, 3);
      expect(e.dirty, isTrue); // sync-ready: unsynced local change
    });

    test(
      'persists across restarts, removes, and survives corruption',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repo = await SharedPrefsVocabularyRepository.create();
        await repo.save(entry());
        final reopened = await SharedPrefsVocabularyRepository.create();
        expect(reopened.containsExpression('long_time_no_see'), isTrue);
        await reopened.remove('id-1');
        expect((await SharedPrefsVocabularyRepository.create()).all, isEmpty);

        SharedPreferences.setMockInitialValues({
          SharedPrefsVocabularyRepository.storageKey: '{broken',
        });
        expect((await SharedPrefsVocabularyRepository.create()).all, isEmpty);
      },
    );
  });

  group('central progress service', () {
    test(
      'completeActivity awards XP once at full value, persists, unlocks',
      () async {
        final store = InMemoryProgressStore(
          const LearnerProgress(onboarded: true, native: NativeLanguage.oromo),
        );
        final c = await AppController.load(
          course: DemoCourse.course,
          store: store,
          clock: () => DateTime(2026, 11, 21, 10),
        );
        const a = LearningActivity(
          id: 'media:bus_stop_hello',
          type: ActivityType.mediaLesson,
          native: NativeLanguage.oromo,
        );
        final first = await c.completeActivity(a);
        expect(first.xpEarned, ActivityXp.mediaLesson);
        expect(first.firstCompletion, isTrue);
        expect(first.streakAfter, 1);
        expect(
          first.newAchievements.map((x) => x.id),
          contains(AchievementId.sceneStarter),
        );
        final again = await c.completeActivity(a);
        expect(again.xpEarned, 5);
        expect(store.value!.totalXp, 20);
        expect(store.value!.completedActivityIds, {'media:bus_stop_hello'});
        expect(store.value!.dailyFor(c.today).xp, 20);
      },
    );

    test('revision XP scales with cards and is capped', () {
      expect(
        ActivityXp.forCompletion(
          ActivityType.revision,
          repeat: false,
          units: 3,
        ),
        6,
      );
      expect(
        ActivityXp.forCompletion(
          ActivityType.revision,
          repeat: false,
          units: 50,
        ),
        20,
      );
    });

    test('onboarding stores profile preferences with a local id', () async {
      final store = InMemoryProgressStore();
      final c = await AppController.load(
        course: DemoCourse.course,
        store: store,
      );
      await c.chooseLanguages(
        NativeLanguage.amharic,
        TargetLanguage.english,
        level: LearnerLevel.elementary,
      );
      final p = store.value!.profile;
      expect(p.nativeLanguage, NativeLanguage.amharic);
      expect(p.level, LearnerLevel.elementary);
      expect(p.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(p.createdAt, isNotNull);
    });
  });

  test(
    'second scene (family moments) is listed, playable and translated',
    () async {
      final all = await BundledContentRepository(bundle: DiskBundle()).list();
      expect(
        all.map((c) => c.id),
        containsAll(['bus_stop_hello', 'family_moments']),
      );
      final c = all.firstWhere((c) => c.id == 'family_moments');
      expect(File(c.media.localAsset!).existsSync(), isTrue);
      expect(File(c.media.localAsset!).lengthSync(), lessThan(10 << 20));
      final t = await BundledTranscriptRepository(bundle: DiskBundle())
          .load(c, languages: codes);
      expect(t.segments, hasLength(3));
      for (final s in t.segments) {
        for (final code in codes) {
          expect(s.translations[code], isNotEmpty, reason: '${s.id} $code');
        }
      }
      expect(t.expressions, hasLength(3));
      for (final e in t.expressions) {
        for (final code in codes) {
          expect(e.meaning[code], isNotEmpty, reason: '${e.id} $code');
        }
      }
    },
  );
}
