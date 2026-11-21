import '../models/localized.dart';

/// Exercise instructions with a native-language helper line.
/// NOTE: native strings need native-speaker review before release.
abstract final class Instructions {
  static const chooseMeaning = Instruction(
    'What does this mean?',
    Localized(am: 'ይህ ምን ማለት ነው?', om: 'Kun maal jechuudha?'),
  );
  static const chooseTranslation = Instruction(
    'Select the correct translation',
    Localized(am: 'ትክክለኛውን ትርጉም ይምረጡ', om: 'Hiika sirrii filadhu'),
  );
  static const typeAnswer = Instruction(
    'Write this in English',
    Localized(am: 'ይህን በእንግሊዝኛ ይጻፉ', om: 'Kana Afaan Ingiliziitiin barreessi'),
  );
  static const buildSentence = Instruction(
    'Build the sentence in English',
    Localized(
      am: 'ዓረፍተ ነገሩን በእንግሊዝኛ ይገንቡ',
      om: 'Hima kana Afaan Ingiliziitiin ijaari',
    ),
  );
  static const matchPairs = Instruction(
    'Match the pairs',
    Localized(am: 'ጥንዶቹን ያዛምዱ', om: 'Jechoota walsimsiisi'),
  );
}
