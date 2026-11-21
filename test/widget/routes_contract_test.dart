import 'package:ethio_linguo/core/navigation/app_routes.dart';
import 'package:ethio_linguo/data/models/conversation.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

// Every shared route resolves. See docs/INTEGRATION_CONTRACTS.md §2.
void main() {
  final cases = <String, (Object?, String)>{
    AppRoutes.discover: (null, 'Discover'),
    AppRoutes.mediaLesson: (
      const MediaLessonArgs('bus_stop_hello'),
      'Long time no see',
    ),
    AppRoutes.speak: (
      const TutorContext(native: NativeLanguage.amharic),
      'The Professor',
    ),
    AppRoutes.myWords: (null, 'My Words'),
    AppRoutes.revision: (null, 'Review My Words'),
    AppRoutes.garden: (null, 'Word Garden'),
    AppRoutes.achievements: (null, 'Badges & progress'),
  };
  for (final MapEntry(key: route, value: (args, title)) in cases.entries) {
    testWidgets('route $route opens its screen', (t) async {
      await pumpApp(t, progress: onboarded());
      await openRoute(t, route, arguments: args);
      expect(find.text(title), findsWidgets);
      expect(t.takeException(), isNull);
    });
  }
}
