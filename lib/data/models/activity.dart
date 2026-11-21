// SHARED CONTRACT (v2): activities and the central XP rule table.

import 'gamification.dart';
import 'language.dart';

enum ActivityType { pathLesson, mediaLesson, revision, tutorConversation }

/// Something a learner can complete for XP. `activityData` carries
/// type-specific parameters without new columns per activity type.
class LearningActivity {
  const LearningActivity({
    required this.id,
    required this.type,
    required this.native,
    this.contentId,
    this.difficulty = 1,
    this.target = TargetLanguage.english,
    this.activityData = const {},
  });

  /// Stable id, e.g. `media:bus_stop_hello`, `revision:2026-11-21`.
  final String id;
  final ActivityType type;
  final String? contentId;
  final int difficulty;
  final NativeLanguage native;
  final TargetLanguage target;
  final Map<String, Object?> activityData;
}

/// The ONLY place XP values for non-path activities are defined.
abstract final class ActivityXp {
  static const mediaLesson = 15;
  static const revisionPerCard = 2;
  static const revisionMax = 20;
  static const tutorConversation = 20;

  /// Repeat completions keep the habit rewarding without farming.
  static int forCompletion(
    ActivityType type, {
    required bool repeat,
    int units = 0,
  }) {
    final base = switch (type) {
      ActivityType.mediaLesson => mediaLesson,
      ActivityType.revision => (units * revisionPerCard).clamp(0, revisionMax),
      ActivityType.tutorConversation => tutorConversation,
      ActivityType.pathLesson => 0, // path lessons use xpFor(LessonResult)
    };
    return repeat ? (base / 3).ceil() : base;
  }
}

/// What completing an activity earned — drives celebration UI.
class ActivityReward {
  const ActivityReward({
    required this.activityId,
    required this.xpEarned,
    required this.firstCompletion,
    required this.streakBefore,
    required this.streakAfter,
    required this.levelBefore,
    required this.levelAfter,
    required this.newAchievements,
  });

  final String activityId;
  final int xpEarned;
  final bool firstCompletion;
  final int streakBefore;
  final int streakAfter;
  final LevelInfo levelBefore;
  final LevelInfo levelAfter;
  final List<Achievement> newAchievements;

  bool get leveledUp => levelAfter.level > levelBefore.level;
  bool get streakExtended => streakAfter > streakBefore;
}
