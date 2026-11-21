import 'language.dart';

/// Calendar day key (yyyy-mm-dd) in local time.
String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

int daysBetween(String fromKey, String toKey) {
  final a = DateTime.parse(fromKey);
  final b = DateTime.parse(toKey);
  return DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// Growth stage of a word in the Word Garden.
enum GrowthStage { seed, sprout, bud, bloom }

class WordProgress {
  const WordProgress({required this.strength, required this.lastPracticed});

  /// 0 = seed … 3 = bloom (mastered).
  final int strength;
  final String lastPracticed;

  static const maxStrength = 3;

  /// Days before a word at a given strength "needs water" (gentle spaced practice).
  static const _intervals = [1, 2, 4, 7];

  GrowthStage get stage => GrowthStage.values[strength.clamp(0, maxStrength)];

  bool needsWater(String today) =>
      daysBetween(lastPracticed, today) >=
      _intervals[strength.clamp(0, maxStrength)];

  WordProgress copyWith({int? strength, String? lastPracticed}) => WordProgress(
    strength: strength ?? this.strength,
    lastPracticed: lastPracticed ?? this.lastPracticed,
  );

  Map<String, Object?> toJson() => {'s': strength, 'p': lastPracticed};

  factory WordProgress.fromJson(Map<String, Object?> j) => WordProgress(
    strength: (j['s'] as num?)?.toInt() ?? 0,
    lastPracticed: j['p'] as String? ?? '1970-01-01',
  );
}

/// Per-day counters powering daily quests.
class DailyStats {
  const DailyStats({
    required this.day,
    this.xp = 0,
    this.lessons = 0,
    this.perfectLessons = 0,
  });

  final String day;
  final int xp;
  final int lessons;
  final int perfectLessons;

  Map<String, Object?> toJson() => {
    'd': day,
    'xp': xp,
    'l': lessons,
    'pl': perfectLessons,
  };

  factory DailyStats.fromJson(Map<String, Object?> j) => DailyStats(
    day: j['d'] as String? ?? '1970-01-01',
    xp: (j['xp'] as num?)?.toInt() ?? 0,
    lessons: (j['l'] as num?)?.toInt() ?? 0,
    perfectLessons: (j['pl'] as num?)?.toInt() ?? 0,
  );
}

/// Everything persisted about the learner. Immutable; updated via copyWith.
class LearnerProgress {
  const LearnerProgress({
    this.onboarded = false,
    this.native,
    this.target = TargetLanguage.english,
    this.totalXp = 0,
    this.streak = 0,
    this.lastActiveDay,
    this.hearts = maxHearts,
    this.heartsDay,
    this.completedNodeIds = const {},
    this.perfectNodeIds = const {},
    this.words = const {},
    this.daily,
    this.longestCorrectRun = 0,
  });

  static const maxHearts = 5;
  static const schemaVersion = 1;

  final bool onboarded;
  final NativeLanguage? native;
  final TargetLanguage target;
  final int totalXp;
  final int streak;
  final String? lastActiveDay;
  final int hearts;

  /// Day the hearts were last refilled.
  final String? heartsDay;
  final Set<String> completedNodeIds;
  final Set<String> perfectNodeIds;
  final Map<String, WordProgress> words;
  final DailyStats? daily;
  final int longestCorrectRun;

  DailyStats dailyFor(String today) =>
      daily != null && daily!.day == today ? daily! : DailyStats(day: today);

  /// Streak as it should be displayed today (broken streaks show 0).
  int streakOn(String today) {
    if (lastActiveDay == null) return 0;
    return daysBetween(lastActiveDay!, today) <= 1 ? streak : 0;
  }

  bool activeOn(String today) => lastActiveDay == today;

  LearnerProgress copyWith({
    bool? onboarded,
    NativeLanguage? native,
    TargetLanguage? target,
    int? totalXp,
    int? streak,
    String? lastActiveDay,
    int? hearts,
    String? heartsDay,
    Set<String>? completedNodeIds,
    Set<String>? perfectNodeIds,
    Map<String, WordProgress>? words,
    DailyStats? daily,
    int? longestCorrectRun,
  }) => LearnerProgress(
    onboarded: onboarded ?? this.onboarded,
    native: native ?? this.native,
    target: target ?? this.target,
    totalXp: totalXp ?? this.totalXp,
    streak: streak ?? this.streak,
    lastActiveDay: lastActiveDay ?? this.lastActiveDay,
    hearts: hearts ?? this.hearts,
    heartsDay: heartsDay ?? this.heartsDay,
    completedNodeIds: completedNodeIds ?? this.completedNodeIds,
    perfectNodeIds: perfectNodeIds ?? this.perfectNodeIds,
    words: words ?? this.words,
    daily: daily ?? this.daily,
    longestCorrectRun: longestCorrectRun ?? this.longestCorrectRun,
  );

  Map<String, Object?> toJson() => {
    'v': schemaVersion,
    'onboarded': onboarded,
    'native': native?.code,
    'target': target.code,
    'xp': totalXp,
    'streak': streak,
    'lastActive': lastActiveDay,
    'hearts': hearts,
    'heartsDay': heartsDay,
    'completed': completedNodeIds.toList(),
    'perfect': perfectNodeIds.toList(),
    'words': {for (final e in words.entries) e.key: e.value.toJson()},
    'daily': daily?.toJson(),
    'run': longestCorrectRun,
  };

  factory LearnerProgress.fromJson(Map<String, Object?> j) {
    final wordsJson = (j['words'] as Map?)?.cast<String, Object?>() ?? {};
    return LearnerProgress(
      onboarded: j['onboarded'] as bool? ?? false,
      native: NativeLanguage.fromCode(j['native'] as String?),
      target:
          TargetLanguage.fromCode(j['target'] as String?) ??
          TargetLanguage.english,
      totalXp: (j['xp'] as num?)?.toInt() ?? 0,
      streak: (j['streak'] as num?)?.toInt() ?? 0,
      lastActiveDay: j['lastActive'] as String?,
      hearts: (j['hearts'] as num?)?.toInt() ?? maxHearts,
      heartsDay: j['heartsDay'] as String?,
      completedNodeIds: ((j['completed'] as List?) ?? const [])
          .cast<String>()
          .toSet(),
      perfectNodeIds: ((j['perfect'] as List?) ?? const [])
          .cast<String>()
          .toSet(),
      words: {
        for (final e in wordsJson.entries)
          e.key: WordProgress.fromJson(
            (e.value as Map).cast<String, Object?>(),
          ),
      },
      daily: j['daily'] == null
          ? null
          : DailyStats.fromJson((j['daily'] as Map).cast<String, Object?>()),
      longestCorrectRun: (j['run'] as num?)?.toInt() ?? 0,
    );
  }
}
