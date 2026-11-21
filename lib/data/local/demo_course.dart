import '../../core/theme/app_colors.dart';
import '../models/course.dart';
import '../models/localized.dart';

/// Local, bundled demo course: English for Amharic and Afaan Oromo speakers.
///
/// Everything here ships inside the app binary — no network needed.
/// NOTE: native-language strings should be reviewed by native speakers before
/// any public release.
abstract final class DemoCourse {
  static const terms = <String, Term>{
    'hello': Term(
      id: 'hello',
      english: 'hello',
      native: Localized(am: 'ሰላም', om: 'Akkam'),
      alsoAccept: ['hi'],
    ),
    'thank_you': Term(
      id: 'thank_you',
      english: 'thank you',
      native: Localized(am: 'አመሰግናለሁ', om: 'Galatoomi'),
      alsoAccept: ['thanks', 'thankyou'],
    ),
    'yes': Term(
      id: 'yes',
      english: 'yes',
      native: Localized(am: 'አዎ', om: 'Eeyyee'),
    ),
    'no': Term(
      id: 'no',
      english: 'no',
      native: Localized(am: 'አይ', om: 'Lakki'),
    ),
    'friend': Term(
      id: 'friend',
      english: 'friend',
      native: Localized(am: 'ጓደኛ', om: 'Hiriyaa'),
    ),
    'coffee': Term(
      id: 'coffee',
      english: 'coffee',
      native: Localized(am: 'ቡና', om: 'Buna'),
    ),
    'water': Term(
      id: 'water',
      english: 'water',
      native: Localized(am: 'ውሃ', om: 'Bishaan'),
    ),
    'bread': Term(
      id: 'bread',
      english: 'bread',
      native: Localized(am: 'ዳቦ', om: 'Daabboo'),
    ),
    'tea': Term(
      id: 'tea',
      english: 'tea',
      native: Localized(am: 'ሻይ', om: 'Shaayii'),
    ),
    'milk': Term(
      id: 'milk',
      english: 'milk',
      native: Localized(am: 'ወተት', om: 'Aannan'),
    ),
  };

  static const sentences = <String, Sentence>{
    'hello_my_friend': Sentence(
      id: 'hello_my_friend',
      englishTokens: ['Hello', 'my', 'friend'],
      native: Localized(am: 'ሰላም ጓደኛዬ', om: 'Akkam hiriyaa koo'),
      termIds: ['hello', 'friend'],
    ),
    'thank_you_friend': Sentence(
      id: 'thank_you_friend',
      englishTokens: ['Thank', 'you', 'my', 'friend'],
      native: Localized(am: 'አመሰግናለሁ ጓደኛዬ', om: 'Galatoomi hiriyaa koo'),
      termIds: ['thank_you', 'friend'],
    ),
    'coffee_and_bread': Sentence(
      id: 'coffee_and_bread',
      englishTokens: ['Coffee', 'and', 'bread'],
      native: Localized(am: 'ቡና እና ዳቦ', om: 'Buna fi daabboo'),
      termIds: ['coffee', 'bread'],
    ),
    'tea_and_milk': Sentence(
      id: 'tea_and_milk',
      englishTokens: ['Tea', 'and', 'milk'],
      native: Localized(am: 'ሻይ እና ወተት', om: 'Shaayii fi aannan'),
      termIds: ['tea', 'milk'],
    ),
  };

  static const lessons = <String, LessonContent>{
    'l_greetings': LessonContent(
      id: 'l_greetings',
      newTermIds: ['hello', 'thank_you', 'yes', 'no', 'friend'],
      exercises: [
        ChooseMeaningSpec('hello', ['friend', 'yes', 'thank_you']),
        ChooseTranslationSpec('thank_you', ['hello', 'no', 'friend']),
        TypeAnswerSpec('friend'),
        MatchPairsSpec(['hello', 'yes', 'no', 'friend']),
        BuildSentenceSpec('hello_my_friend', ['the', 'yes', 'water']),
        ChooseMeaningSpec('no', ['yes', 'hello', 'friend']),
        BuildSentenceSpec('thank_you_friend', ['hello', 'no']),
      ],
    ),
    'l_coffee': LessonContent(
      id: 'l_coffee',
      newTermIds: ['coffee', 'water', 'bread', 'tea', 'milk'],
      exercises: [
        ChooseMeaningSpec('coffee', ['water', 'tea', 'bread']),
        ChooseTranslationSpec('water', ['milk', 'coffee', 'bread']),
        MatchPairsSpec(['coffee', 'water', 'bread', 'tea']),
        TypeAnswerSpec('bread'),
        BuildSentenceSpec('coffee_and_bread', ['water', 'the', 'yes']),
        ChooseMeaningSpec('milk', ['tea', 'water', 'coffee']),
        BuildSentenceSpec('tea_and_milk', ['bread', 'no']),
      ],
    ),
  };

  static const _unit1Words = [
    'hello',
    'thank_you',
    'yes',
    'no',
    'friend',
    'coffee',
    'water',
    'bread',
    'tea',
    'milk',
  ];

  static final units = <Unit>[
    const Unit(
      id: 'u1',
      number: 1,
      title: 'First words',
      subtitle: 'Greet people and order at the coffee ceremony',
      color: AppColors.teal,
      shade: AppColors.tealShade,
      nodes: [
        PathNode(
          id: 'n_greetings',
          title: 'Say hello',
          kind: NodeKind.lesson,
          lessonId: 'l_greetings',
        ),
        PathNode(
          id: 'n_coffee',
          title: 'Coffee time',
          kind: NodeKind.lesson,
          lessonId: 'l_coffee',
        ),
        PathNode(
          id: 'n_u1_practice',
          title: 'Mix & review',
          kind: NodeKind.practice,
          reviewTermIds: _unit1Words,
        ),
        PathNode(
          id: 'n_u1_check',
          title: 'Unit 1 checkpoint',
          kind: NodeKind.checkpoint,
          reviewTermIds: _unit1Words,
        ),
      ],
    ),
    const Unit(
      id: 'u2',
      number: 2,
      title: 'Around town',
      subtitle: 'People, places and getting around',
      color: AppColors.periwinkle,
      shade: AppColors.periwinkleShade,
      nodes: [
        PathNode(id: 'n_people', title: 'People', kind: NodeKind.lesson),
        PathNode(id: 'n_places', title: 'Places', kind: NodeKind.lesson),
        PathNode(id: 'n_numbers', title: 'Numbers', kind: NodeKind.lesson),
        PathNode(
          id: 'n_u2_check',
          title: 'Unit 2 checkpoint',
          kind: NodeKind.checkpoint,
        ),
      ],
    ),
    const Unit(
      id: 'u3',
      number: 3,
      title: 'My day',
      subtitle: 'Time, routines and family',
      color: AppColors.coral,
      shade: AppColors.coralShade,
      nodes: [
        PathNode(id: 'n_time', title: 'Telling time', kind: NodeKind.lesson),
        PathNode(id: 'n_family', title: 'Family', kind: NodeKind.lesson),
        PathNode(
          id: 'n_u3_check',
          title: 'Unit 3 checkpoint',
          kind: NodeKind.checkpoint,
        ),
      ],
    ),
  ];

  static final course = Course(
    units: units,
    terms: terms,
    sentences: sentences,
    lessons: lessons,
  );
}
