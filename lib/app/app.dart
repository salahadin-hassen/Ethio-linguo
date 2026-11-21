import 'package:flutter/material.dart';

import '../core/navigation/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/home/home_shell.dart';
import '../features/language_selection/language_selection_screen.dart';
import '../features/lessons/lesson_complete_screen.dart';
import '../features/lessons/lesson_launch.dart';
import '../features/lessons/lesson_screen.dart';
import '../features/media_lesson/media_lesson_screen.dart';
import '../features/my_words/my_words_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/revision/revision_screen.dart';
import '../features/word_garden/word_garden_screen.dart';
import '../features/speak/speak_screen.dart';
import '../data/models/conversation.dart';
import 'app_config.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'app_services.dart';

class LearningApp extends StatelessWidget {
  LearningApp({super.key, required this.controller, AppServices? services})
    : services = services ?? AppServices.inMemory();

  final AppController controller;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: services,
      child: AppScope(
        controller: controller,
        child: MaterialApp(
          title: AppConfig.workingTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          initialRoute: controller.progress.onboarded
              ? AppRoutes.home
              : AppRoutes.welcome,
          onGenerateRoute: _route,
          onUnknownRoute: (s) =>
              AppPageRoute(builder: (_) => const WelcomeScreen(), settings: s),
        ),
      ),
    );
  }

  static Route<dynamic>? _route(RouteSettings s) {
    final Widget Function(BuildContext) b;
    switch (s.name) {
      case AppRoutes.welcome:
        b = (_) => const WelcomeScreen();
      case AppRoutes.language:
        b = (_) => const LanguageSelectionScreen();
      case AppRoutes.home:
        final tab = s.arguments;
        b = (_) => HomeShell(
          initialTab: tab is HomeTab ? tab.index : (tab is int ? tab : 0),
        );
      case AppRoutes.lesson:
        final launch = s.arguments;
        if (launch is! LessonLaunch) return null;
        return AppPageRoute(
          builder: (_) => LessonScreen(launch: launch),
          settings: s,
          fullscreenDialog: true,
        );
      case AppRoutes.complete:
        final reward = s.arguments;
        if (reward is! LessonReward) return null;
        b = (_) => LessonCompleteScreen(reward: reward);
      case AppRoutes.discover:
        b = (_) => const DiscoverScreen();
      case AppRoutes.mediaLesson:
        final args = s.arguments;
        if (args is! MediaLessonArgs) return null;
        b = (_) => MediaLessonScreen(args: args);
      case AppRoutes.speak:
        final ctx = s.arguments;
        b = (_) => SpeakScreen(tutorContext: ctx is TutorContext ? ctx : null);
      case AppRoutes.myWords:
        b = (_) => const MyWordsScreen();
      case AppRoutes.revision:
        b = (_) => const RevisionScreen();
      case AppRoutes.garden:
        b = (_) => const Scaffold(body: SafeArea(child: WordGardenScreen()));
      case AppRoutes.achievements:
        b = (_) => const Scaffold(body: SafeArea(child: AchievementsScreen()));
      default:
        return null;
    }
    return AppPageRoute(builder: b, settings: s);
  }
}
