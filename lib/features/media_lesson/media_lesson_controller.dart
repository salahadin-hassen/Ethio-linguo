import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/app_controller.dart';
import '../../app/app_services.dart';
import '../../core/util/local_id.dart';
import '../../data/models/activity.dart';
import '../../data/models/content.dart';
import '../../data/models/conversation.dart';
import '../../data/models/language.dart';
import '../../data/models/transcript.dart';
import '../../data/models/vocabulary.dart';
import '../../services/analytics/analytics.dart';
import '../../services/playback/media_playback.dart';

enum MediaLessonPhase { loading, ready, error }

/// Application logic for one media lesson. Owns the player (and disposes
/// it), maps playback position to transcript segments, and talks to the
/// vocabulary repository and the central progress service.
class MediaLessonController extends ChangeNotifier {
  MediaLessonController({
    required this.contentId,
    required this._services,
    required this._progress,
  });

  final String contentId;
  final AppServices _services;
  final AppController _progress;

  MediaLessonPhase phase = MediaLessonPhase.loading;
  String? error;
  LearningContent? content;
  Transcript? transcript;
  MediaPlayback? playback;

  TranscriptSegment? current;
  bool showTranslation = true;
  bool completed = false;

  /// Segment to stop at when replaying a single line.
  TranscriptSegment? _replayUntil;
  bool _disposed = false;

  NativeLanguage get native => _progress.native;

  Future<void> load() async {
    try {
      final c = await _services.content.byId(contentId);
      if (c == null) throw StateError('This lesson is not available.');
      final t = await _services.transcripts.load(
        c,
        languages: [for (final l in NativeLanguage.values) l.code],
      );
      final p = _services.playbackFactory(c.media);
      await p.initialize();
      if (_disposed) {
        await p.dispose();
        return;
      }
      content = c;
      transcript = t;
      playback = p..state.addListener(_onTick);
      final err = p.state.value.error;
      phase = err == null ? MediaLessonPhase.ready : MediaLessonPhase.error;
      error = err;
      _services.analytics.log(AnalyticsEvent.lessonStarted, {
        'contentId': c.id,
        'type': c.type.name,
      });
    } catch (e) {
      phase = MediaLessonPhase.error;
      error = e is StateError ? e.message : 'This lesson could not be opened.';
    }
    if (!_disposed) notifyListeners();
  }

  void _onTick() {
    final s = playback!.state.value;
    final seg = transcript!.segmentAt(s.positionMs);
    if (_replayUntil != null && s.positionMs >= _replayUntil!.endMs) {
      _replayUntil = null;
      unawaited(playback!.pause());
    }
    if (!identical(seg, current)) {
      current = seg;
      notifyListeners();
    }
    if (s.completed && !completed) {
      completed = true;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    final p = playback;
    if (p == null) return;
    _replayUntil = null;
    p.state.value.playing ? await p.pause() : await p.play();
  }

  /// Replays [segment] (or the current/last line) and stops at its end.
  Future<void> replay([TranscriptSegment? segment]) async {
    final p = playback;
    final t = transcript;
    if (p == null || t == null) return;
    final seg =
        segment ??
        t.segmentAtOrBefore(p.state.value.positionMs) ??
        t.segments.first;
    _replayUntil = seg;
    await p.seekTo(seg.startMs);
    await p.play();
  }

  Future<void> step(int delta) async {
    final t = transcript;
    final p = playback;
    if (t == null || p == null) return;
    final at = t.segmentAtOrBefore(p.state.value.positionMs);
    final i = at == null ? -1 : t.indexOf(at);
    final next = (i + delta).clamp(0, t.segments.length - 1);
    await replay(t.segments[next]);
  }

  void toggleTranslation() {
    showTranslation = !showTranslation;
    notifyListeners();
  }

  /// Tapping an expression pauses playback so the learner can read.
  Future<void> onExpressionSelected(Expression e) async {
    await playback?.pause();
    _services.analytics.log(AnalyticsEvent.subtitleSelected, {
      'contentId': contentId,
      'expressionId': e.id,
    });
  }

  bool isSaved(Expression e) => _services.vocabulary.containsExpression(e.id);

  Future<void> save(Expression e) async {
    final c = content!, t = transcript!;
    if (isSaved(e)) return;
    final seg = t.segmentById(e.segmentId)!;
    await _services.vocabulary.save(
      VocabularyEntry.fromExpression(
        id: newLocalId(),
        learnerId: _progress.profile.id,
        content: c,
        segment: seg,
        expression: e,
        now: _progress.now,
      ),
    );
    _services.analytics.log(AnalyticsEvent.vocabularySaved, {
      'contentId': c.id,
      'expressionId': e.id,
    });
    notifyListeners();
  }

  /// Completes the lesson through the central progress service.
  Future<ActivityReward> finish() async {
    await playback?.pause();
    final reward = await _progress.completeActivity(
      LearningActivity(
        id: 'media:$contentId',
        type: ActivityType.mediaLesson,
        contentId: contentId,
        native: native,
        difficulty: content?.difficulty ?? 1,
      ),
    );
    _services.analytics.log(AnalyticsEvent.lessonCompleted, {
      'contentId': contentId,
      'xp': reward.xpEarned,
    });
    return reward;
  }

  /// Lesson context for the Professor (structured, not a free prompt).
  TutorContext tutorContext({Expression? focus}) {
    final c = content!, t = transcript!;
    final saved = [
      for (final e in t.expressions)
        if (isSaved(e)) e.text,
    ];
    return TutorContext(
      native: native,
      level: _progress.profile.level,
      contentId: c.id,
      contentTitle: c.title,
      sceneSummary: c.sceneSummary,
      transcript: [
        for (final s in t.segments)
          '${c.speakers[s.speakerId] ?? 'Speaker'}: ${s.originalText}',
      ],
      focusExpression: focus?.text,
      targetExpressions: saved.isEmpty
          ? [for (final e in t.expressions.take(3)) e.text]
          : saved,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    playback?.state.removeListener(_onTick);
    unawaited(playback?.dispose());
    super.dispose();
  }
}
