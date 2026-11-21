import 'package:ethio_linguo/core/navigation/app_routes.dart';
import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/services/tutor/tutor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

// Every shared route resolves. See docs/INTEGRATION_CONTRACTS.md §2.
void main() {
  final cases = <String, (Object?, String)>{
    AppRoutes.discover: (null, 'Discover'),
    AppRoutes.mediaLesson: (const MediaLessonArgs('demo_clip'), 'Media lesson'),
    AppRoutes.speak: (
      const TutorContext(native: NativeLanguage.amharic),
      'Speak',
    ),
    AppRoutes.myWords: (null, 'My Words'),
  };
  for (final MapEntry(key: route, value: (args, title)) in cases.entries) {
    testWidgets('route $route opens its screen', (t) async {
      await pumpApp(t, progress: onboarded());
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed(route, arguments: args);
      await t.pumpAndSettle();
      expect(find.text(title), findsWidgets);
    });
  }
}
