import 'language.dart';

/// Text authored once per supported native language.
class Localized {
  const Localized({required this.am, required this.om});

  final String am;
  final String om;

  String of(NativeLanguage lang) => switch (lang) {
    NativeLanguage.amharic => am,
    NativeLanguage.oromo => om,
  };
}

/// An exercise instruction: English heading plus a native-language helper line.
class Instruction {
  const Instruction(this.en, this.native);

  final String en;
  final Localized native;
}
