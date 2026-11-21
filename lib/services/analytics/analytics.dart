import 'package:flutter/foundation.dart';

/// Product events. Names are stable (snake_case) so a future provider can
/// map them 1:1. Properties must never contain speech, transcripts, names or
/// other personal data — ids and counts only.
enum AnalyticsEvent {
  lessonStarted('lesson_started'),
  lessonCompleted('lesson_completed'),
  subtitleSelected('subtitle_selected'),
  vocabularySaved('vocabulary_saved'),
  revisionCompleted('revision_completed'),
  tutorSessionStarted('tutor_session_started'),
  tutorSessionCompleted('tutor_session_completed'),
  mediaDownloaded('media_downloaded'),
  offlineLessonCompleted('offline_lesson_completed');

  const AnalyticsEvent(this.wireName);
  final String wireName;
}

abstract interface class Analytics {
  void log(AnalyticsEvent event, [Map<String, Object> props = const {}]);
}

/// Default: debug console only, nothing leaves the device. No paid provider.
class DebugAnalytics implements Analytics {
  const DebugAnalytics();

  @override
  void log(AnalyticsEvent event, [Map<String, Object> props = const {}]) {
    if (kDebugMode) debugPrint('[event] ${event.wireName} $props');
  }
}

/// Test double that records events.
class RecordingAnalytics implements Analytics {
  final events = <(AnalyticsEvent, Map<String, Object>)>[];

  @override
  void log(AnalyticsEvent event, [Map<String, Object> props = const {}]) =>
      events.add((event, props));

  bool logged(AnalyticsEvent e) => events.any((x) => x.$1 == e);
}
