import '../../data/models/language.dart';
import '../../data/models/progress.dart';
import '../mascot/characters.dart';

/// One thing a character says: short English line (the language being
/// learned), optional support line in the learner's language, and the
/// character state that should accompany it.
class Line {
  const Line(this.en, this.state, {this.am, this.om});
  final String en;
  final String? am;
  final String? om;
  final CharacterState state;

  String? native(NativeLanguage l) => switch (l) {
    NativeLanguage.amharic => am,
    NativeLanguage.oromo => om,
  };
}

/// Spark's voice: a warm, upbeat companion. Never guilt-tripping.
/// Pure functions of REAL progress so reactions track actual state.
/// Native support lines are DRAFTS pending native-speaker review.
abstract final class SparkLines {
  static Line greeting({
    required LearnerProgress p,
    required String today,
    required int hour,
    required int thirstyWords,
    required bool questsDone,
    required int xpGainedSinceLastVisit,
  }) {
    if (xpGainedSinceLastVisit > 0) {
      return Line(
        '+$xpGainedSinceLastVisit XP! You\'re on a roll.',
        CharacterState.excited,
        am: 'በጣም ጎበዝ!',
        om: 'Baay\'ee gaarii!',
      );
    }
    if (p.completedNodeIds.isEmpty && p.completedActivityIds.isEmpty) {
      return const Line(
        'Hi, I\'m Spark! Your first lesson takes 3 minutes.',
        CharacterState.waving,
        am: 'ሰላም! እኔ ስፓርክ ነኝ።',
        om: 'Akkam! Ani Spaark.',
      );
    }
    final gap = p.lastActiveDay == null
        ? 0
        : daysBetween(p.lastActiveDay!, today);
    if (gap >= 2) {
      return const Line(
        'Welcome back! Let\'s pick up right where you left off.',
        CharacterState.greeting,
        am: 'እንኳን ደህና መጡ!',
        om: 'Baga nagaan deebitan!',
      );
    }
    if (questsDone) {
      return const Line(
        'All quests done today. That\'s a champion day!',
        CharacterState.celebrating,
        am: 'ዛሬ ሁሉንም ጨርሰዋል!',
        om: 'Har\'a hunda xumurtaniittu!',
      );
    }
    if (p.lastActiveDay == today) {
      return Line(
        p.streak >= 3
            ? '${p.streak}-day streak! One more scene?'
            : 'Nice work today. One more scene?',
        CharacterState.happy,
      );
    }
    if (thirstyWords > 0) {
      return Line(
        '$thirstyWords ${thirstyWords == 1 ? 'word needs' : 'words need'} water in your garden.',
        CharacterState.curious,
      );
    }
    if (p.streak >= 2) {
      return Line(
        'Your ${p.streak}-day streak is waiting. Five minutes?',
        CharacterState.encouraging,
      );
    }
    return Line(
      hour < 12
          ? 'Morning! A short lesson is a great start.'
          : hour < 17
          ? 'Got five minutes? Let\'s learn a phrase.'
          : 'Evening practice sticks best. Ready?',
      CharacterState.idle,
    );
  }

  /// Things Spark says when tapped (cycled, not random, so it feels
  /// intentional and never repeats back-to-back).
  static const tips = [
    Line('Tap a gold phrase in a video to learn it.', CharacterState.happy),
    Line(
      'Say it out loud — the Professor is listening!',
      CharacterState.excited,
    ),
    Line('Saved words grow in your Word Garden.', CharacterState.encouraging),
    Line('Mistakes are how we learn. Keep going!', CharacterState.happy),
  ];

  static Line lessonStart(int exercises) => Line(
    '$exercises quick ones. You\'ve got this!',
    CharacterState.encouraging,
  );

  static const correct = [
    Line('Yes! That\'s it.', CharacterState.happy),
    Line('Perfect!', CharacterState.excited),
    Line('You\'re getting good at this.', CharacterState.happy),
  ];

  static const almost = Line(
    'So close — tiny typo!',
    CharacterState.encouraging,
  );

  static const wrong = [
    Line(
      'Not quite. Look at the answer, then try again.',
      CharacterState.encouraging,
    ),
    Line('Good try! This one is tricky.', CharacterState.encouraging),
  ];
}
