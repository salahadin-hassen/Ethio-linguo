import 'package:ethio_linguo/app/app_controller.dart';
import 'package:ethio_linguo/data/local/demo_course.dart';
import 'package:ethio_linguo/data/local/progress_store.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/data/models/media.dart';
import 'package:ethio_linguo/data/models/progress.dart';
import 'package:ethio_linguo/data/models/saved_expression.dart';
import 'package:ethio_linguo/data/repositories/media_repository.dart';
import 'package:ethio_linguo/data/repositories/vocabulary_repository.dart';
import 'package:ethio_linguo/services/tutor/tutor_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Guards the shared integration contracts (docs/INTEGRATION_CONTRACTS.md).
// Translation strings below are schema placeholders, not real translations.

final _manifest = <String, Object?>{
  'v': 1,
  'id': 'demo_clip',
  'title': 'Demo clip',
  'videoAsset': 'assets/content/media/demo_clip/clip.mp4',
  'durationMs': 6000,
  'license': {'kind': 'original', 'attribution': 'Hackathon team'},
  'sceneSummary': 'Two friends meet at a bus stop.',
  'level': 1,
  'segments': [
    {
      'id': 's1',
      'startMs': 0,
      'endMs': 2500,
      'en': 'Long time no see!',
      'translations': {'am': '<am>', 'om': '<om>'},
      'expressionIds': ['long_time_no_see'],
    },
    {
      'id': 's2',
      'startMs': 2500,
      'endMs': 6000,
      'en': 'I know, it has been ages.',
      'translations': {'am': '<am>', 'om': '<om>'},
    },
  ],
  'expressions': [
    {
      'id': 'long_time_no_see',
      'en': 'Long time no see',
      'meaning': {'am': '<am>', 'om': '<om>'},
      'explanation': {'am': '<am>', 'om': '<om>'},
      'reviewed': false,
    },
  ],
};

void main() {
  test('media manifest round-trips and finds the active subtitle', () {
    final m = MediaItem.fromJson(_manifest);
    expect(MediaItem.fromJson(m.toJson()).toJson(), m.toJson());
    expect(m.segmentAt(1000)!.id, 's1');
    expect(m.segmentAt(2500)!.id, 's2');
    expect(m.segmentAt(6000), isNull);
    expect(m.segments.first.translations.of(NativeLanguage.oromo), '<om>');
    expect(m.expression('long_time_no_see')!.reviewed, isFalse);
  });

  test('in-memory media repository resolves by id', () async {
    final repo = InMemoryMediaRepository([MediaItem.fromJson(_manifest)]);
    expect((await repo.byId('demo_clip'))!.title, 'Demo clip');
    expect(await repo.byId('missing'), isNull);
  });

  test('saved expressions persist, dedupe by id and survive restart', () async {
    SharedPreferences.setMockInitialValues({});
    final m = MediaItem.fromJson(_manifest);
    final e = SavedExpression.fromMedia(
      media: m,
      segment: m.segments.first,
      expression: m.expressions.first,
      now: DateTime(2026, 11, 21),
    );
    final repo = await SharedPrefsVocabularyRepository.create();
    var notified = 0;
    repo.addListener(() => notified++);
    await repo.save(e);
    await repo.save(e);
    await repo.markReviewed(e.id);
    expect(repo.all, hasLength(1));
    expect(notified, 3);

    final reopened = await SharedPrefsVocabularyRepository.create();
    expect(reopened.contains('long_time_no_see'), isTrue);
    expect(reopened.all.single.contextLine, 'Long time no see!');
    expect(reopened.all.single.reviewCount, 1);
    await reopened.remove(e.id);
    expect(reopened.all, isEmpty);
  });

  test('corrupt vocabulary data starts empty instead of crashing', () async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsVocabularyRepository.storageKey: '{not json',
    });
    final repo = await SharedPrefsVocabularyRepository.create();
    expect(repo.all, isEmpty);
  });

  test('recordActivity adds XP, daily XP and starts a streak', () async {
    final store = InMemoryProgressStore(
      const LearnerProgress(onboarded: true, native: NativeLanguage.amharic),
    );
    final c = await AppController.load(
      course: DemoCourse.course,
      store: store,
      clock: () => DateTime(2026, 11, 21, 10),
    );
    final xp = await c.recordActivity(activityId: 'media:demo_clip', xp: 15);
    expect(xp, 15);
    expect(c.progress.totalXp, 15);
    expect(c.progress.dailyFor(c.today).xp, 15);
    expect(c.streak, 1);
    expect(store.saves, 1);
  });

  test('default tutor is honestly unavailable', () async {
    const service = UnavailableTutorService();
    expect((await service.availability()).live, isFalse);
    final session = service.open(
      const TutorContext(native: NativeLanguage.amharic),
    );
    expect(session.state.value, TutorState.unavailable);
    await session.end();
    expect(session.state.value, TutorState.ended);
  });
}
