import 'package:flutter/widgets.dart' show TextDirection;

/// Writing system of a language. Drives font fallback and layout checks.
enum Script { latin, ethiopic, arabic }

/// What the product can currently do in a language. Content can exist for a
/// language before the UI is localised into it, and vice versa.
enum LanguageCapability {
  uiStrings,
  contentTranslation,
  speechRecognition,
  speechSynthesis,
}

/// Static description of a language (BCP-47 code). Shared by learner
/// preferences, content metadata and AI requests.
class LanguageInfo {
  const LanguageInfo({
    required this.code,
    required this.displayName,
    required this.nativeName,
    required this.script,
    required this.capabilities,
    this.textDirection = TextDirection.ltr,
    this.speechLocale,
  });

  /// BCP-47 primary tag: `en`, `am`, `om`.
  final String code;
  final String displayName;
  final String nativeName;
  final Script script;
  final Set<LanguageCapability> capabilities;

  /// LTR for all current languages; kept explicit so RTL can be added.
  final TextDirection textDirection;

  /// Locale id for on-device speech services, when supported.
  final String? speechLocale;

  bool supports(LanguageCapability c) => capabilities.contains(c);
}

abstract final class Languages {
  static const en = LanguageInfo(
    code: 'en',
    displayName: 'English',
    nativeName: 'English',
    script: Script.latin,
    speechLocale: 'en-US',
    capabilities: {
      LanguageCapability.uiStrings,
      LanguageCapability.speechRecognition,
      LanguageCapability.speechSynthesis,
    },
  );
  static const am = LanguageInfo(
    code: 'am',
    displayName: 'Amharic',
    nativeName: 'አማርኛ',
    script: Script.ethiopic,
    capabilities: {
      LanguageCapability.uiStrings,
      LanguageCapability.contentTranslation,
    },
  );
  static const om = LanguageInfo(
    code: 'om',
    displayName: 'Afaan Oromo',
    nativeName: 'Afaan Oromoo',
    script: Script.latin,
    capabilities: {
      LanguageCapability.uiStrings,
      LanguageCapability.contentTranslation,
    },
  );

  static const all = [en, am, om];

  static LanguageInfo? byCode(String? code) {
    for (final l in all) {
      if (l.code == code) return l;
    }
    return null;
  }
}

/// Self-reported English level, chosen during onboarding.
enum LearnerLevel {
  beginner(1, 'New to English', 'I know a few words'),
  elementary(2, 'Some English', 'I can say simple sentences'),
  conversational(3, 'Conversational', 'I can hold a short conversation');

  const LearnerLevel(this.rank, this.title, this.subtitle);
  final int rank;
  final String title;
  final String subtitle;

  static LearnerLevel fromRank(int? r) =>
      values.firstWhere((l) => l.rank == r, orElse: () => beginner);
}

/// Languages the learner already speaks (instruction / support language).
enum NativeLanguage {
  amharic(
    code: 'am',
    englishName: 'Amharic',
    endonym: 'አማርኛ',
    greeting: 'ሰላም',
    sample: 'ሰላም፣ እንኳን ደህና መጡ',
    scriptLabel: 'Ethiopic script · ፊደል',
  ),
  oromo(
    code: 'om',
    englishName: 'Afaan Oromo',
    endonym: 'Afaan Oromoo',
    greeting: 'Akkam',
    sample: 'Akkam, baga nagaan dhuftan',
    scriptLabel: 'Latin script · Qubee',
  );

  const NativeLanguage({
    required this.code,
    required this.englishName,
    required this.endonym,
    required this.greeting,
    required this.sample,
    required this.scriptLabel,
  });

  final String code;
  final String englishName;

  /// The language's name in itself.
  final String endonym;

  /// Short greeting used for personalised welcomes.
  final String greeting;
  final String sample;
  final String scriptLabel;

  LanguageInfo get info => Languages.byCode(code)!;

  static NativeLanguage? fromCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return null;
  }
}

/// Languages being learned. Only English exists in this milestone.
enum TargetLanguage {
  english(code: 'en', name: 'English', available: true),
  french(code: 'fr', name: 'French', available: false),
  arabic(code: 'ar', name: 'Arabic', available: false);

  const TargetLanguage({
    required this.code,
    required this.name,
    required this.available,
  });

  final String code;
  final String name;
  final bool available;

  static TargetLanguage? fromCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return null;
  }
}
