import 'dart:convert';

import 'package:ethio_linguo/app/app_controller.dart';
import 'package:ethio_linguo/app/app_services.dart';
import 'package:ethio_linguo/data/local/demo_course.dart';
import 'package:ethio_linguo/data/local/progress_store.dart';
import 'package:ethio_linguo/data/models/conversation.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/data/models/progress.dart';
import 'package:ethio_linguo/features/speak/tutor_session_controller.dart';
import 'package:ethio_linguo/services/analytics/analytics.dart';
import 'package:ethio_linguo/services/tutor/relay_tutor_engine.dart';
import 'package:ethio_linguo/services/tutor/tutor_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fakes.dart';

const ctx = TutorContext(
  native: NativeLanguage.amharic,
  contentId: 'bus_stop_hello',
  contentTitle: 'Long time no see',
  sceneSummary: 'Two friends meet at a bus stop.',
  transcript: ['Liya: Hey, Dawit! Long time no see!'],
  targetExpressions: ['Long time no see', 'catch up'],
);

void main() {
  group('RelayTutorEngine (wire contract v1)', () {
    test('sends structured lesson context and parses the reply', () async {
      late Map<String, Object?> sent;
      final engine = RelayTutorEngine(
        Uri.parse('http://relay.test'),
        client: MockClient((req) async {
          expect(req.url.path, '/v1/tutor/turn');
          sent = jsonDecode(req.body) as Map<String, Object?>;
          return http.Response(
            jsonEncode({
              'reply': {'text': 'Great!', 'translation': 'በጣም ጥሩ!'},
              'feedback': {
                'kind': 'word_choice',
                'note': 'Say "catch up".',
                'noteNative': '…',
                'suggestion': "Let's catch up.",
              },
              'suggestedExpression': 'catch up',
              'usedExpressions': ['Long time no see'],
              'done': false,
              'speech': null,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final r = await engine.respond(
        const TutorRequest(
          sessionId: 's',
          context: ctx,
          history: [TutorTurn(speaker: Speaker.tutor, text: 'Hi!')],
          utterance: 'long time no see',
          sttConfidence: 0.8,
        ),
      );
      final learner = sent['learner'] as Map;
      expect(learner['nativeLanguage'], 'am');
      expect(learner['targetLanguage'], 'en');
      expect((sent['lesson'] as Map)['sceneSummary'], ctx.sceneSummary);
      expect(sent['targetExpressions'], ctx.targetExpressions);
      expect((sent['utterance'] as Map)['text'], 'long time no see');
      expect(r.replyText, 'Great!');
      expect(r.feedback!.kind, FeedbackKind.wordChoice);
      expect(r.feedback!.suggestion, "Let's catch up.");
      expect(r.usedExpressions, ['Long time no see']);
    });

    test('maps relay errors and outages to typed exceptions', () async {
      final down = RelayTutorEngine(
        Uri.parse('http://relay.test'),
        client: MockClient(
          (_) async => http.Response(
            '{"error":{"code":"unavailable","message":"No provider"}}',
            503,
          ),
        ),
      );
      expect(
        () => down.respond(
          const TutorRequest(sessionId: 's', context: ctx, history: []),
        ),
        throwsA(
          isA<TutorException>().having(
            (e) => e.code,
            'code',
            TutorErrorCode.unavailable,
          ),
        ),
      );
      final offline = RelayTutorEngine(
        Uri.parse('http://relay.test'),
        client: MockClient((_) => throw http.ClientException('no route')),
      );
      expect((await offline.availability()).live, isFalse);
    });
  });

  group('TutorSessionController', () {
    Future<
      (TutorSessionController, InMemoryProgressStore, AppServices, FakeSynth)
    >
    make(TutorEngine engine) async {
      final store = InMemoryProgressStore(
        const LearnerProgress(onboarded: true, native: NativeLanguage.amharic),
      );
      final app = await AppController.load(
        course: DemoCourse.course,
        store: store,
        clock: () => DateTime(2026, 11, 21, 10),
      );
      final synth = FakeSynth();
      final services = AppServices.inMemory(
        tutor: engine,
        speechIn: FakeRecognizer(),
        speechOut: synth,
        analytics: RecordingAnalytics(),
      );
      return (
        TutorSessionController(context: ctx, services: services, progress: app),
        store,
        services,
        synth,
      );
    }

    test(
      'speech -> tutor -> speech, feedback, XP after 3 learner turns',
      () async {
        final tutor = FakeLiveTutor();
        final (c, store, services, synth) = await make(tutor);
        await c.start();
        expect(c.state, TutorState.idle);
        expect(c.turns.single.speaker, Speaker.tutor);
        expect(synth.spoken, hasLength(1)); // opening line spoken aloud

        await c.startListening(); // FakeRecognizer delivers a final result
        await pumpEventQueue();
        expect(c.turns[1].text, 'Long time no see');
        expect(c.turns[1].feedback!.kind, FeedbackKind.great);
        expect(tutor.requests.last.context.sceneSummary, ctx.sceneSummary);

        await c.sendText('i been busy');
        expect(c.turns[3].feedback!.suggestion, 'I have been busy.');
        expect(await c.end(), isNull, reason: 'only 2 learner turns: no XP');

        await c.sendText('lets catch up');
        // ended state blocks input; restart a fresh conversation instead
        final (c2, store2, services2, _) = await make(FakeLiveTutor());
        await c2.start();
        for (final t in ['hello', 'Long time no see', 'lets catch up soon']) {
          await c2.sendText(t);
        }
        final reward = await c2.end();
        expect(reward!.xpEarned, 20);
        expect(
          store2.value!.completedActivityIds,
          contains('tutor:bus_stop_hello'),
        );
        expect(
          services2.conversations.recent.single.usedExpressions,
          containsAll(['Long time no see', 'catch up']),
        );
        expect(store.value!.totalXp, 0);
        expect(services.conversations.recent, isEmpty);
      },
    );

    test('no provider: honest unavailable state, never a fake reply', () async {
      final (c, store, _, synth) = await make(const UnavailableTutorEngine());
      await c.start();
      expect(c.state, TutorState.unavailable);
      expect(c.turns, isEmpty);
      expect(synth.spoken, isEmpty);
      expect(await c.end(), isNull);
      expect(store.value!.totalXp, 0);
    });

    test('provider failure -> error with retry, then unavailable', () async {
      final tutor = FakeLiveTutor();
      final (c, _, _, _) = await make(tutor);
      await c.start();
      tutor.failWith = const TutorException(TutorErrorCode.timeout, 'slow');
      await c.sendText('hello');
      expect(c.state, TutorState.error);
      expect(c.turns.last.text, 'hello'); // transcript kept
      await c.retry();
      expect(c.state, TutorState.unavailable);
    });
  });
}
