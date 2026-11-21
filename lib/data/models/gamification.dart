import 'progress.dart';

/// Learning level derived from total XP.
class LevelInfo {
  const LevelInfo(this.level, this.xpIntoLevel, this.xpForLevel);

  final int level;
  final int xpIntoLevel;
  final int xpForLevel;

  double get fraction => xpForLevel == 0 ? 0 : xpIntoLevel / xpForLevel;

  /// Thresholds grow gently so early levels come quickly.
  static int costOf(int level) => 40 + (level - 1) * 30;

  static LevelInfo fromXp(int xp) {
    var level = 1;
    var remaining = xp;
    while (remaining >= costOf(level)) {
      remaining -= costOf(level);
      level++;
    }
    return LevelInfo(level, remaining, costOf(level));
  }
}

enum QuestKind { earnXp, completeLessons, perfectLesson }

class DailyQuest {
  const DailyQuest({
    required this.kind,
    required this.title,
    required this.goal,
    required this.progress,
  });

  final QuestKind kind;
  final String title;
  final int goal;
  final int progress;

  bool get done => progress >= goal;
  double get fraction => (progress / goal).clamp(0, 1).toDouble();

  static List<DailyQuest> forDay(DailyStats s) => [
    DailyQuest(
      kind: QuestKind.earnXp,
      title: 'Earn 30 XP',
      goal: 30,
      progress: s.xp,
    ),
    DailyQuest(
      kind: QuestKind.completeLessons,
      title: 'Complete 2 lessons',
      goal: 2,
      progress: s.lessons,
    ),
    DailyQuest(
      kind: QuestKind.perfectLesson,
      title: 'Finish a lesson with no mistakes',
      goal: 1,
      progress: s.perfectLessons,
    ),
  ];
}

enum AchievementId {
  firstSteps,
  perfectionist,
  onFire,
  gardener,
  firstBloom,
  checkpoint,
  sceneStarter,
  wordKeeper,
  firstConversation,
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.progress,
    required this.goal,
  });

  final AchievementId id;
  final String title;
  final String description;
  final bool unlocked;
  final int progress;
  final int goal;

  double get fraction => (progress / goal).clamp(0, 1).toDouble();

  static List<Achievement> evaluate(
    LearnerProgress p, {
    required Set<String> checkpointIds,
  }) {
    final blooms = p.words.values
        .where((w) => w.stage == GrowthStage.bloom)
        .length;
    final checkpoints = p.completedNodeIds.intersection(checkpointIds).length;
    int done(String prefix) =>
        p.completedActivityIds.where((a) => a.startsWith(prefix)).length;
    Achievement a(
      AchievementId id,
      String t,
      String d,
      int progress,
      int goal,
    ) => Achievement(
      id: id,
      title: t,
      description: d,
      unlocked: progress >= goal,
      progress: progress.clamp(0, goal),
      goal: goal,
    );
    return [
      a(
        AchievementId.firstSteps,
        'First Steps',
        'Complete your first lesson',
        p.completedNodeIds.length,
        1,
      ),
      a(
        AchievementId.perfectionist,
        'Clear Voice',
        'Finish a lesson with no mistakes',
        p.perfectNodeIds.length,
        1,
      ),
      a(
        AchievementId.onFire,
        'Steady Flame',
        'Reach a 3-day streak',
        p.streak,
        3,
      ),
      a(
        AchievementId.gardener,
        'Gardener',
        'Plant 8 words in your Word Garden',
        p.words.length,
        8,
      ),
      a(
        AchievementId.firstBloom,
        'First Bloom',
        'Grow a word to full bloom',
        blooms,
        1,
      ),
      a(
        AchievementId.checkpoint,
        'Trailblazer',
        'Pass a unit checkpoint',
        checkpoints,
        1,
      ),
      a(
        AchievementId.sceneStarter,
        'Scene Starter',
        'Finish your first video lesson',
        done('media:'),
        1,
      ),
      a(
        AchievementId.wordKeeper,
        'Word Keeper',
        'Complete a My Words review',
        done('revision:'),
        1,
      ),
      a(
        AchievementId.firstConversation,
        'First Conversation',
        'Talk with the Professor',
        done('tutor:'),
        1,
      ),
    ];
  }
}
