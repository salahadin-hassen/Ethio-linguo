import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../data/models/conversation.dart';
import 'relay_endpoint.dart';
import 'tutor_engine.dart';

/// TutorEngine backed by the team's relay (server/, contract v1). The relay
/// holds provider credentials; this app holds none.
class RelayTutorEngine implements TutorEngine {
  RelayTutorEngine(Uri baseUrl, {http.Client? client})
    : this.at(RelayEndpoint(baseUrl), client: client);

  /// Follows [endpoint], which the learner/presenter can change on device.
  RelayTutorEngine.at(this.endpoint, {http.Client? client})
    : _client = client ?? http.Client();

  final RelayEndpoint endpoint;
  final http.Client _client;

  Uri get baseUrl => endpoint.url ?? _unset;

  /// Set from /v1/health: the relay can stream turns (reply first).
  bool _streaming = false;

  @override
  Future<TutorAvailability> availability() async {
    if (endpoint.url == null) {
      return const TutorAvailability.unavailable(
        'No tutor server is set. Enter the relay address below.',
      );
    }
    try {
      final res = await _client
          .get(baseUrl.resolve('/v1/health'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) {
        return TutorAvailability.unavailable(
          'Tutor relay returned ${res.statusCode}.',
        );
      }
      final j = jsonDecode(res.body) as Map;
      _streaming = j['streaming'] == true;
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

  Map<String, Object?> _body(TutorRequest r) {
    final c = r.context;
    return {
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
      'voice': r.wantsVoice,
    };
  }

  @override
  Future<TutorResponse> respond(
    TutorRequest r, {
    void Function(String reply)? onReply,
  }) async {
    final body = jsonEncode(_body(r));
    if (_streaming) {
      final streamed = await _respondStream(body, onReply);
      if (streamed != null) return streamed;
      _streaming = false; // relay without the stream route: stop trying
    }
    return _respondOnce(body);
  }

  static TutorException _error(Object? code, String? message, int status) =>
      TutorException(switch (code) {
        'unavailable' => TutorErrorCode.unavailable,
        'rate_limited' => TutorErrorCode.rateLimited,
        'bad_request' => TutorErrorCode.badRequest,
        _ => TutorErrorCode.providerError,
      }, message ?? 'Tutor error $status');

  /// NDJSON events: {"type":"reply"} as soon as the line is known, then
  /// {"type":"turn"} or {"type":"error"}. Null = route not supported.
  Future<TutorResponse?> _respondStream(
    String body,
    void Function(String reply)? onReply,
  ) async {
    final http.StreamedResponse res;
    try {
      final req = http.Request('POST', baseUrl.resolve('/v1/tutor/turn/stream'))
        ..headers['content-type'] = 'application/json'
        ..body = body;
      res = await _client.send(req).timeout(const Duration(seconds: 15));
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
    if (res.statusCode == 404) {
      await res.stream.drain<void>();
      return null;
    }
    if (res.statusCode != 200) {
      final text = await res.stream.bytesToString();
      Map? err;
      try {
        err = (jsonDecode(text) as Map)['error'] as Map?;
      } catch (_) {}
      throw _error(err?['code'], err?['message'] as String?, res.statusCode);
    }
    try {
      await for (final line
          in res.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(const Duration(seconds: 30))) {
        if (line.trim().isEmpty) continue;
        final e = (jsonDecode(line) as Map).cast<String, Object?>();
        switch (e['type']) {
          case 'reply':
            final t = e['text'];
            if (t is String && t.trim().isNotEmpty) onReply?.call(t.trim());
          case 'turn':
            return parseResponse((e['turn']! as Map).cast<String, Object?>());
          case 'error':
            final err = (e['error'] as Map?) ?? const {};
            throw _error(err['code'], err['message'] as String?, 200);
        }
      }
    } on TutorException {
      rethrow;
    } on TimeoutException {
      throw const TutorException(
        TutorErrorCode.timeout,
        'The Professor took too long to answer.',
      );
    } catch (_) {
      throw const TutorException(
        TutorErrorCode.providerError,
        'The connection to the Professor broke. Try again.',
      );
    }
    throw const TutorException(
      TutorErrorCode.providerError,
      'The Professor\'s answer was cut off. Try again.',
    );
  }

  Future<TutorResponse> _respondOnce(String body) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            baseUrl.resolve('/v1/tutor/turn'),
            headers: {'content-type': 'application/json'},
            body: body,
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
      throw _error(err['code'], err['message'] as String?, res.statusCode);
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
  RelayNativeVoice(Uri baseUrl, {http.Client? client})
    : this.at(RelayEndpoint(baseUrl), client: client);

  RelayNativeVoice.at(this.endpoint, {http.Client? client})
    : _client = client ?? http.Client();

  final RelayEndpoint endpoint;
  Uri get baseUrl => endpoint.url ?? _unset;

  final http.Client _client;

  @override
  Future<bool> available() async {
    if (endpoint.url == null) return false;
    try {
      final res = await _client
          .get(baseUrl.resolve('/v1/health'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return false;
      final speech = (jsonDecode(res.body) as Map)['speech'];
      _speaksEnglish =
          speech is Map &&
          (speech['synthesize'] as List?)?.contains('en') == true;
      return speech != null;
    } catch (_) {
      return false;
    }
  }

  bool _speaksEnglish = false;
  @override
  bool get speaksEnglish => _speaksEnglish;

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

/// Placeholder when no relay is set: requests fail fast as unreachable.
final _unset = Uri.parse('http://relay-not-set.invalid');
