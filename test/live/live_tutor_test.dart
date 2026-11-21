// Calls a REAL running relay (no fakes). Skipped by default; run with:
//   (cd server && npm start) && flutter test test/live --run-skipped
@Tags(['live'])
library;

import 'package:ethio_linguo/data/models/conversation.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/services/tutor/relay_tutor_engine.dart';
import 'package:ethio_linguo/services/tutor/tutor_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = RelayTutorEngine(
    Uri.parse(
      const String.fromEnvironment(
        'RELAY',
        defaultValue: 'http://localhost:8787',
      ),
    ),
  );
  for (final lang in NativeLanguage.values) {
    test('live tutor turn in ${lang.englishName}', () async {
      expect((await engine.availability()).live, isTrue);
      final ctx = TutorContext(
        native: lang,
        contentId: 'bus_stop_hello',
        contentTitle: 'Long time no see',
        sceneSummary: 'Two old friends, Liya and Dawit, meet at a bus stop.',
        transcript: const ['Liya: Hey, Dawit! Long time no see!'],
        targetExpressions: const ['Long time no see', 'catch up'],
      );
      final open = await engine.respond(
        TutorRequest(sessionId: 'live', context: ctx, history: const []),
      );
      final r = await engine.respond(
        TutorRequest(
          sessionId: 'live',
          context: ctx,
          history: [TutorTurn(speaker: Speaker.tutor, text: open.replyText)],
          utterance: 'long time no see i been busy with my new job',
          sttConfidence: 0.8,
        ),
      );
      // ignore: avoid_print
      print(
        '[$lang] ${open.replyText}\n -> ${r.replyText}\n tip: ${r.feedback?.note} | ${r.feedback?.suggestion}',
      );
      expect(r.replyText, isNotEmpty);
      expect(r.feedback, isNotNull);
      expect(open.coach, isNotNull, reason: 'teaches in the learner language');
      expect(open.task, isNotNull);
      final voice = RelayNativeVoice(engine.baseUrl);
      expect(await voice.available(), isTrue);
      final clip = await voice.synthesize(open.coach!, language: lang.code);
      expect(clip.bytes.length, greaterThan(1000));
      // ignore: avoid_print
      print(
        'COACH[${lang.code}] ${open.coach}\nTASK ${open.task!.type.name}: ${open.task!.prompt}\nVOICE ${clip.bytes.length} bytes ${clip.mimeType}',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  }
}
