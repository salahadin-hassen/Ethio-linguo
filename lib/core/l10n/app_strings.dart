import 'package:flutter/widgets.dart';

import '../../app/app_scope.dart';
import '../../data/models/language.dart';

// UI LOCALIZATION (not content translation — see docs/ADR/0005).
//
// The app UI is English (the language being learned) with a short support
// line in the learner's language under key labels. All support lines live
// here, keyed by [S]; widgets never hard-code Amharic or Afaan Oromo.
// Missing entries fall back to English-only (no support line).
// Status: DRAFT strings written by the team, pending native-speaker review.

enum S {
  meaning,
  inThisScene,
  example,
  saveToMyWords,
  saved,
  practiseWithProfessor,
  listen,
  replayLine,
  tapPhraseHint,
  translationOff,
  myWordsEmpty,
  reviewQuestion,
  iRemembered,
  stillLearning,
  professorOffline,
  holdToTalk,
  aiTranslation,
  draftTranslation,
  watchAndLearn,
  yourLevel,
  remove,
}

const _en = <S, String>{
  S.meaning: 'Meaning',
  S.inThisScene: 'In this scene',
  S.example: 'Example',
  S.saveToMyWords: 'Save to My Words',
  S.saved: 'Saved to My Words',
  S.practiseWithProfessor: 'Practise speaking',
  S.listen: 'Listen',
  S.replayLine: 'Replay line',
  S.tapPhraseHint: 'Tap a highlighted phrase to learn it',
  S.translationOff: 'Translation hidden',
  S.myWordsEmpty: 'You have not saved any words yet',
  S.reviewQuestion: 'Do you remember what it means?',
  S.iRemembered: 'I remembered',
  S.stillLearning: 'Still learning',
  S.professorOffline: 'The Professor is offline right now',
  S.holdToTalk: 'Hold to talk',
  S.aiTranslation: 'AI translation',
  S.draftTranslation: 'Draft translation',
  S.watchAndLearn: 'Watch & learn',
  S.yourLevel: 'Your English level',
  S.remove: 'Remove',
};

const _am = <S, String>{
  S.meaning: 'ትርጉም',
  S.inThisScene: 'በዚህ ትዕይንት',
  S.example: 'ምሳሌ',
  S.saveToMyWords: 'በቃላቶቼ ውስጥ አስቀምጥ',
  S.saved: 'ተቀምጧል',
  S.practiseWithProfessor: 'ከፕሮፌሰሩ ጋር ይለማመዱ',
  S.listen: 'ያዳምጡ',
  S.replayLine: 'መስመሩን እንደገና',
  S.tapPhraseHint: 'ለመማር የደመቀውን ሐረግ ይንኩ',
  S.myWordsEmpty: 'እስካሁን ምንም ቃል አላስቀመጡም',
  S.reviewQuestion: 'ትርጉሙን ያስታውሳሉ?',
  S.iRemembered: 'አስታውሻለሁ',
  S.stillLearning: 'ገና እየተማርኩ ነው',
  S.professorOffline: 'ፕሮፌሰሩ አሁን መስመር ላይ አይደሉም',
  S.holdToTalk: 'ለመናገር ተጭነው ይያዙ',
  S.aiTranslation: 'በAI የተተረጎመ',
  S.draftTranslation: 'ረቂቅ ትርጉም',
  S.watchAndLearn: 'ይመልከቱ፣ ይማሩ',
  S.yourLevel: 'የእንግሊዝኛ ደረጃዎ',
  S.remove: 'አስወግድ',
};

const _om = <S, String>{
  S.meaning: 'Hiika',
  S.inThisScene: 'Taatee kana keessatti',
  S.example: 'Fakkeenya',
  S.saveToMyWords: 'Jechoota koo keessa kaa\'i',
  S.saved: 'Kaa\'ameera',
  S.practiseWithProfessor: 'Pirofeesaraa wajjin shaakali',
  S.listen: 'Dhaggeeffadhu',
  S.myWordsEmpty: 'Ammaaf jechi kaa\'ame hin jiru',
  S.reviewQuestion: 'Hiika isaa ni yaadattaa?',
  S.iRemembered: 'Nan yaadadhe',
  S.stillLearning: 'Ammallee barachaan jira',
  S.aiTranslation: 'Hiika AI',
  S.yourLevel: 'Sadarkaa Afaan Ingiliffaa kee',
  S.remove: 'Haqi',
};

class AppStrings {
  const AppStrings(this.lang);

  final NativeLanguage lang;

  static AppStrings of(BuildContext context) =>
      AppStrings(AppScope.of(context).native);

  /// English UI label.
  String en(S key) => _en[key]!;

  /// Support line in the learner's language, or null when not yet written.
  String? native(S key) => switch (lang) {
    NativeLanguage.amharic => _am[key],
    NativeLanguage.oromo => _om[key],
  };

  TextDirection get direction => lang.info.textDirection;

  /// Relative date in English; locale-neutral and calendar-neutral (the
  /// Ethiopian calendar is a future enhancement, see ADR 0005).
  static String relativeDay(DateTime then, DateTime now) {
    final a = DateTime(then.year, then.month, then.day);
    final b = DateTime(now.year, now.month, now.day);
    final d = b.difference(a).inDays;
    if (d <= 0) return 'Today';
    if (d == 1) return 'Yesterday';
    if (d < 7) return '$d days ago';
    if (d < 30) return '${d ~/ 7} wk ago';
    return '${d ~/ 30} mo ago';
  }
}
