import 'package:flutter/material.dart';

import '../core/navigation/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../features/home/home_shell.dart';
import '../features/language_selection/language_selection_screen.dart';
import '../features/lessons/lesson_complete_screen.dart';
import '../features/lessons/lesson_launch.dart';
import '../features/lessons/lesson_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import 'app_config.dart';
import 'app_controller.dart';
import 'app_scope.dart';

class LearningApp extends StatelessWidget {
  const LearningApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
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
        b = (_) =>
            HomeShell(initialTab: s.arguments is int ? s.arguments! as int : 0);
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
      default:
        return null;
    }
    return AppPageRoute(builder: b, settings: s);
  }
}
