import 'dart:convert';

import 'package:ethio_linguo/app/app_controller.dart';
import 'package:ethio_linguo/app/app_services.dart';
import 'package:ethio_linguo/data/local/demo_course.dart';
import 'package:ethio_linguo/data/local/progress_store.dart';
import 'package:ethio_linguo/data/models/conversation.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/data/models/progress.dart';
import 'package:ethio_linguo/features/mascot/characters.dart';
import 'package:ethio_linguo/features/speak/tutor_session_controller.dart';
import 'package:ethio_linguo/services/audio/sound_effects.dart';
import 'package:ethio_linguo/services/analytics/analytics.dart';
import 'package:ethio_linguo/services/tutor/relay_endpoint.dart';
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

    test('streaming relay: reply first, then the turn; errors and old '
        'relays (404) handled', () async {
      final turnJson = {
        'reply': {'text': 'Nice to see you!', 'translation': '-'},
        'coach': 'ጥሩ ነው።',
        'task': {'type': 'repeat', 'prompt': 'Nice to see you!'},
        'feedback': null,
        'usedExpressions': <String>[],
        'done': false,
      };
      var mode = 'ok';
      final paths = <String>[];
      final client = MockClient.streaming((req, body) async {
        paths.add(req.url.path);
        if (req.url.path == '/v1/health') {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode('{"ok":true,"provider":"addis","streaming":true}'),
            ),
            200,
          );
        }
        if (req.url.path == '/v1/tutor/turn') {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(turnJson))),
            200,
          );
        }
        if (mode == 'old') {
          return http.StreamedResponse(Stream.value(utf8.encode('{}')), 404);
        }
        final sent = jsonDecode(await body.bytesToString()) as Map;
        expect(sent['voice'], isTrue);
        final events = mode == 'error'
            ? [
                {'type': 'reply', 'text': 'Hmm.'},
                {
                  'type': 'error',
                  'error': {'code': 'rate_limited', 'message': 'busy'},
                },
              ]
            : [
                {'type': 'reply', 'text': 'Nice to see you!'},
                {'type': 'turn', 'turn': turnJson},
              ];
        return http.StreamedResponse(
          Stream.fromIterable([
            for (final e in events) utf8.encode('${jsonEncode(e)}\n'),
          ]),
          200,
        );
      });
      final engine = RelayTutorEngine(
        Uri.parse('http://relay.test'),
        client: client,
      );
      expect((await engine.availability()).live, isTrue);
      const req = TutorRequest(
        sessionId: 's',
        context: ctx,
        history: [],
        wantsVoice: true,
      );
      final early = <String>[];
      final r = await engine.respond(req, onReply: early.add);
      expect(early, ['Nice to see you!']);
      expect(r.coach, 'ጥሩ ነው።');
      expect(paths.last, '/v1/tutor/turn/stream');

      mode = 'error';
      await expectLater(
        engine.respond(req),
        throwsA(
          isA<TutorException>().having(
            (e) => e.code,
            'code',
            TutorErrorCode.rateLimited,
          ),
        ),
      );

      mode = 'old';
      final viaOld = await engine.respond(req, onReply: early.add);
      expect(viaOld.replyText, 'Nice to see you!');
      expect(paths.last, '/v1/tutor/turn', reason: 'fell back to one-shot');
    });

    test(
      'tutor server address: typed on a phone, saved, followed live',
      () async {
        expect(
          RelayEndpoint.parse('192.168.1.20').toString(),
          'http://192.168.1.20:8787',
        );
        expect(
          RelayEndpoint.parse(' http://10.0.0.5:9000/ ').toString(),
          'http://10.0.0.5:9000',
        );
        expect(
          RelayEndpoint.parse('https://tutor.example.org').toString(),
          'https://tutor.example.org',
        );
        expect(RelayEndpoint.parse(''), isNull);
        expect(RelayEndpoint.parse('ftp://x'), isNull);

        Uri? saved;
        final endpoint = RelayEndpoint(null, onSave: (u) async => saved = u);
        final hosts = <String>[];
        final engine = RelayTutorEngine.at(
          endpoint,
          client: MockClient((req) async {
            hosts.add(req.url.host);
            return http.Response('{"ok":true,"provider":"addis"}', 200);
          }),
        );
        final none = await engine.availability();
        expect(none.live, isFalse);
        expect(none.reason, contains('No tutor server'));
        expect(hosts, isEmpty, reason: 'no request without an address');
        expect(await endpoint.set('not a url ::'), isFalse);
        expect(await endpoint.set('192.168.1.20'), isTrue);
        expect(saved.toString(), 'http://192.168.1.20:8787');
        expect((await engine.availability()).live, isTrue);
        expect(hosts, ['192.168.1.20']);
      },
    );

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
    make(
      TutorEngine engine, {
      bool live = false,
      List<String> phrases = const ['Long time no see'],
      FakeNativeVoice? voice,
      FakeClipPlayer? player,
      FakeRecognizer? recognizer,
    }) async {
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
        speechIn: recognizer ?? FakeRecognizer(phrases: phrases),
        speechOut: synth,
        analytics: RecordingAnalytics(),
        nativeVoice: voice,
        recorder: FakeRecorder(),
        clipPlayer: player,
      );
      final c = TutorSessionController(
        context: ctx,
        services: services,
        progress: app,
      )..liveMode = live;
      return (c, store, services, synth);
    }

    test(
      'speech -> tutor -> speech, feedback, XP after 3 learner turns',
      () async {
        final tutor = FakeLiveTutor();
        final (c, store, services, synth) = await make(tutor);
        await c.start();
        expect(c.state, TutorState.idle);
        expect(c.turns.single.speaker, Speaker.tutor);
        expect(c.currentTask!.type, TaskType.repeat);
        expect(synth.spoken, hasLength(1)); // opening line spoken aloud

        await c.startListening(); // FakeRecognizer delivers a final result
        await pumpEventQueue();
        expect(c.turns[1].text, 'Long time no see');
        expect(c.turns[1].feedback!.kind, FeedbackKind.great);
        // "Repeat" task scored locally against the target sentence.
        expect(c.turns[1].repeatScore!.passed, isTrue);
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

    test('live mode: mic re-opens after each reply; coach spoken in native language', () async {
      final voice = FakeNativeVoice();
      final player = FakeClipPlayer();
      final (c, _, _, synth) = await make(
        FakeLiveTutor(),
        live: true,
        phrases: ['long time no', 'I have been busy with my new job'],
        voice: voice,
        player: player,
      );
      await c.start();
      await pumpEventQueue();
      // opening -> heard "long time no" -> reply -> heard 2nd phrase -> reply
      expect(c.turns.where((t) => t.speaker == Speaker.learner), hasLength(2));
      expect(c.turns[1].repeatScore!.missing, ['see']);
      expect(c.turns[1].repeatScore!.passed, isFalse);
      expect(
        c.state,
        TutorState.listening,
        reason: 'hands-free: waiting again',
      );
      expect(voice.spoken.first, startsWith('am:'));
      expect(player.plays, 3);
      expect(synth.spoken, hasLength(3));
    });

    test(
      'native clip drives the jaw from its real loudness envelope',
      () async {
        final voice = FakeNativeVoice()
          ..envelope = const AmplitudeEnvelope(50, [0, 0.5, 1, 0.25]);
        final player = FakeClipPlayer()
          ..positions = const [
            Duration.zero,
            Duration(milliseconds: 50),
            Duration(milliseconds: 100),
            Duration(milliseconds: 125),
          ];
        final (c, _, _, _) = await make(
          FakeLiveTutor(),
          voice: voice,
          player: player,
        );
        final seen = <double?>[];
        c.voiceLevel.addListener(() => seen.add(c.voiceLevel.value));
        await c.start();
        await pumpEventQueue();
        expect(player.plays, greaterThan(0));
        // silence is held just open enough to stay in the audio-driven state
        expect(seen.take(4), [0.02, 0.5, 1.0, closeTo(0.625, 1e-9)]);
        expect(c.voiceLevel.value, isNull, reason: 'cleared after playback');
      },
    );

    test('envelope: parse, interpolate, silent past the end', () {
      final e = AmplitudeEnvelope.fromJson({
        'frameMs': 50,
        'values': [0, 1, 2, 'x'],
      })!;
      expect(e.values, [0.0, 1.0, 1.0, 0.0]);
      expect(e.at(const Duration(milliseconds: 25)), closeTo(0.5, 1e-9));
      expect(e.at(const Duration(seconds: 5)), 0);
      expect(
        AmplitudeEnvelope.fromJson({
          'frameMs': 0,
          'values': [1],
        }),
        isNull,
      );
      expect(AmplitudeEnvelope.fromJson(null), isNull);
    });

    test(
      'question in the native language is transcribed and answered',
      () async {
        final voice = FakeNativeVoice();
        final tutor = FakeLiveTutor();
        final (c, _, _, _) = await make(tutor, voice: voice);
        await c.start();
        await c.startNativeQuestion();
        expect(c.state, TutorState.recordingNative);
        await c.stopNativeQuestion();
        expect(tutor.requests.last.utteranceLanguage, 'am');
        expect(c.turns[1].language, 'am');
        expect(c.turns.last.coach, contains('catch up'));
        expect(c.learnerTurns, 0, reason: 'questions are not English practice');
      },
    );

    test('Professor state + real mic level follow the session', () async {
      final (c, _, services, _) = await make(FakeLiveTutor());
      await c.start();
      expect(c.professorState, CharacterState.idle);
      await c.startListening();
      await pumpEventQueue();
      // FakeRecognizer reported a level then a final result; after the
      // reply the mic is closed so the meter is cleared (never faked).
      expect(c.level.value, isNull);
      expect(c.professorState, CharacterState.approving);
      expect(
        (services.sounds as SilentSoundEffects).played,
        contains(Sfx.correct),
      );
      await c.sendText('i been busy');
      expect(c.professorState, CharacterState.correcting);
    });

    test('corrections can be saved to My Words', () async {
      final (c, _, services, _) = await make(FakeLiveTutor());
      await c.start();
      await c.sendText('i been busy');
      await c.saveCorrection(c.corrections.single);
      final e = services.vocabulary.all.single;
      expect(e.originalExpression, 'I have been busy.');
      expect(e.source.name, 'tutor');
    });

    test('no provider: honest unavailable state, never a fake reply', () async {
      final (c, store, _, synth) = await make(const UnavailableTutorEngine());
      await c.start();
      expect(c.state, TutorState.unavailable);
      expect(c.turns, isEmpty);
      expect(synth.spoken, isEmpty);
      expect(await c.end(), isNull);
      expect(store.value!.totalXp, 0);
    });

    test('provider failure -> error with retry; a network blip never ends '
        'the session, repeated failures do', () async {
      final tutor = FakeLiveTutor();
      final (c, _, _, _) = await make(tutor);
      await c.start();
      tutor.failWith = const TutorException(TutorErrorCode.timeout, 'slow');
      await c.sendText('hello');
      expect(c.state, TutorState.error);
      expect(c.turns.last.text, 'hello'); // transcript kept
      await c.retry();
      expect(c.state, TutorState.error, reason: 'still recoverable');
      await c.retry();
      expect(c.state, TutorState.unavailable);
    });

    test(
      'hands-free: a failed turn retries itself once and recovers',
      () async {
        final tutor = FakeLiveTutor()..failTimes = 1;
        final (c, _, _, _) = await make(tutor, live: true, phrases: []);
        await c.start();
        expect(c.state, TutorState.error);
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        expect(tutor.requests, hasLength(2), reason: 'retried automatically');
        expect(c.turns.single.speaker, Speaker.tutor);
        expect(c.state, isNot(TutorState.error));
        c.dispose();
      },
    );

    test('natural English voice: relay clip plays instead of the phone '
        'voice; on failure the phone voice speaks the line once', () async {
      final voice = FakeNativeVoice()..english = true;
      final player = FakeClipPlayer();
      final (c, _, _, synth) = await make(
        FakeLiveTutor()..streams = true,
        voice: voice,
        player: player,
      );
      await c.start();
      expect(
        voice.spoken.first,
        'en:Hey! Long time no see! How have you been?',
      );
      expect(synth.spoken, isEmpty, reason: 'no double voice');
      expect(player.plays, 2, reason: 'English clip, then coaching');

      final failing = FakeNativeVoice()
        ..english = true
        ..englishFails = true;
      final (c2, _, _, synth2) = await make(
        FakeLiveTutor()..streams = true,
        voice: failing,
      );
      await c2.start();
      expect(synth2.spoken, ['Hey! Long time no see! How have you been?']);
      expect(failing.spoken.where((s) => s.startsWith('en:')), isEmpty);
      expect(failing.spoken.single, startsWith('am:'), reason: 'coaching kept');
    });

    test('streamed reply: spoken as soon as it arrives, once, then completed '
        'with coaching and task', () async {
      final tutor = FakeLiveTutor()..streams = true;
      final voice = FakeNativeVoice();
      final (c, _, _, synth) = await make(tutor, voice: voice);
      await c.start();
      expect(synth.spoken, ['Hey! Long time no see! How have you been?']);
      expect(c.turns, hasLength(1), reason: 'early line replaced in place');
      expect(c.turns.single.coach, isNotNull);
      expect(c.currentTask!.type, TaskType.repeat);
      expect(tutor.requests.single.wantsVoice, isTrue);
      expect(voice.spoken, hasLength(1), reason: 'coaching voiced after');
    });

    test('repeat task: sent as soon as every word is heard (no silence '
        'wait)', () async {
      final (c, _, _, _) = await make(
        FakeLiveTutor(),
        recognizer: FakeRecognizer(
          phrases: ['long time no see'],
          partialOnly: true, // no final result: only our endpointing can send
        ),
      );
      await c.start();
      expect(c.currentTask!.prompt, 'Long time no see!');
      await c.startListening();
      expect(c.state, TutorState.listening);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      final learner = c.turns.firstWhere((t) => t.speaker == Speaker.learner);
      expect(learner.text, 'long time no see');
      expect(learner.repeatScore!.passed, isTrue);
      c.dispose();
    });
  });
}
