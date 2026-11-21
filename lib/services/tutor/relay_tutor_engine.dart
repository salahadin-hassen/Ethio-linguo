import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../data/models/conversation.dart';
import 'tutor_engine.dart';

/// TutorEngine backed by the team's relay (server/, contract v1). The relay
/// holds provider credentials; this app holds none.
class RelayTutorEngine implements TutorEngine {
  RelayTutorEngine(this.baseUrl, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUrl;
  final http.Client _client;

  @override
  Future<TutorAvailability> availability() async {
    try {
      final res = await _client
          .get(baseUrl.resolve('/v1/health'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) {
        return TutorAvailability.unavailable(
          'Tutor relay returned ${res.statusCode}.',
        );
      }
      final j = jsonDecode(res.body) as Map;
      return j['ok'] == true
          ? TutorAvailability.live(provider: j['provider'] as String?)
          : const TutorAvailability.unavailable(
              'Tutor relay has no AI provider configured.',
            );
    } catch (_) {
      return const TutorAvailability.unavailable(
        'Can\'t reach the Professor. Check your internet connection.',
      );
    }
  }

  @override
  Future<TutorResponse> respond(TutorRequest r) async {
    final c = r.context;
    final body = {
      'sessionId': r.sessionId,
      'character': r.characterId,
      'learner': {
        'nativeLanguage': c.native.code,
        'targetLanguage': c.target.code,
        'level': c.level.rank,
      },
      'lesson': c.hasLesson
          ? {
              'contentId': c.contentId,
              'title': c.contentTitle,
              'sceneSummary': c.sceneSummary,
              'transcript': c.transcript,
            }
          : null,
      'focusExpression': c.focusExpression,
      'targetExpressions': c.targetExpressions,
      'history': [
        for (final t in r.history) {'speaker': t.speaker.name, 'text': t.text},
      ],
      'utterance': r.utterance == null
          ? null
          : {
              'text': r.utterance,
              'sttConfidence': r.sttConfidence,
              'language': r.utteranceLanguage,
            },
    };
    final http.Response res;
    try {
      res = await _client
          .post(
            baseUrl.resolve('/v1/tutor/turn'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const TutorException(
        TutorErrorCode.timeout,
        'The Professor took too long to answer.',
      );
    } catch (_) {
      throw const TutorException(
        TutorErrorCode.unavailable,
        'Can\'t reach the Professor.',
      );
    }
    final Map<String, Object?> j;
    try {
      j = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)
          .cast<String, Object?>();
    } catch (_) {
      throw const TutorException(
        TutorErrorCode.providerError,
        'Unexpected reply from the tutor relay.',
      );
    }
    if (res.statusCode != 200) {
      final err = (j['error'] as Map?) ?? const {};
      throw TutorException(switch (err['code']) {
        'unavailable' => TutorErrorCode.unavailable,
        'rate_limited' => TutorErrorCode.rateLimited,
        'bad_request' => TutorErrorCode.badRequest,
        _ => TutorErrorCode.providerError,
      }, (err['message'] as String?) ?? 'Tutor error ${res.statusCode}');
    }
    return parseResponse(j);
  }

  static TutorResponse parseResponse(Map<String, Object?> j) {
    final reply = (j['reply']! as Map).cast<String, Object?>();
    final f = (j['feedback'] as Map?)?.cast<String, Object?>();
    return TutorResponse(
      replyText: reply['text']! as String,
      replyTranslation: reply['translation'] as String?,
      feedback: f == null
          ? null
          : TutorFeedback(
              kind: switch (f['kind']) {
                'grammar' => FeedbackKind.grammar,
                'word_choice' => FeedbackKind.wordChoice,
                'pronunciation' => FeedbackKind.pronunciation,
                _ => FeedbackKind.great,
              },
              note: f['note']! as String,
              noteNative: f['noteNative'] as String?,
              suggestion: f['suggestion'] as String?,
            ),
      suggestedExpression: j['suggestedExpression'] as String?,
      usedExpressions: [...?(j['usedExpressions'] as List?)?.cast<String>()],
      done: j['done'] as bool? ?? false,
      speechUrl: j['speech'] as String?,
      coach: _nonEmpty(j['coach']),
      hint: _nonEmpty(j['hint']),
      task: _task(j['task']),
    );
  }

  static String? _nonEmpty(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static TutorTask? _task(Object? v) {
    if (v is! Map || _nonEmpty(v['prompt']) == null) return null;
    return TutorTask(
      type: switch (v['type']) {
        'repeat' => TaskType.repeat,
        'use_expression' => TaskType.useExpression,
        _ => TaskType.answer,
      },
      prompt: _nonEmpty(v['prompt'])!,
      promptNative: _nonEmpty(v['promptNative']),
    );
  }
}

/// Native-language speech through the relay (/v1/speech/*). Audio is sent
/// once for transcription and never stored by the app or the relay.
class RelayNativeVoice implements NativeVoice {
  RelayNativeVoice(this.baseUrl, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUrl;
  final http.Client _client;

  @override
  Future<bool> available() async {
    try {
      final res = await _client
          .get(baseUrl.resolve('/v1/health'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200 &&
          (jsonDecode(res.body) as Map)['speech'] != null;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, Object?>> _post(
    Uri url,
    Object body,
    Map<String, String> headers,
  ) async {
    final http.Response res;
    try {
      res = await _client
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 35));
    } on TimeoutException {
      throw const TutorException(
        TutorErrorCode.timeout,
        'Voice service took too long.',
      );
    } catch (_) {
      throw const TutorException(
        TutorErrorCode.unavailable,
        'Can\'t reach the voice service.',
      );
    }
    final j = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)
        .cast<String, Object?>();
    if (res.statusCode != 200) {
      throw TutorException(
        TutorErrorCode.providerError,
        ((j['error'] as Map?)?['message'] as String?) ??
            'Voice error ${res.statusCode}',
      );
    }
    return j;
  }

  @override
  Future<SpeechClip> synthesize(String text, {required String language}) async {
    final j = await _post(
      baseUrl.resolve('/v1/speech/synthesize'),
      jsonEncode({'text': text, 'language': language}),
      {'content-type': 'application/json'},
    );
    return SpeechClip(
      base64Decode(j['audioBase64']! as String),
      (j['mimeType'] as String?) ?? 'audio/mpeg',
      envelope: AmplitudeEnvelope.fromJson(j['envelope']),
    );
  }

  @override
  Future<String> transcribe(List<int> wav, {required String language}) async {
    final j = await _post(
      baseUrl.resolve('/v1/speech/transcribe?language=$language'),
      Uint8List.fromList(wav),
      {'content-type': 'audio/wav'},
    );
    return (j['text'] as String?)?.trim() ?? '';
  }
}
