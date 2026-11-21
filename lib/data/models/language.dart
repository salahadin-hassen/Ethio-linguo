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
