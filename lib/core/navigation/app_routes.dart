import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// SHARED CONTRACT — see docs/INTEGRATION_CONTRACTS.md §2.
/// Route names are frozen; add new ones by PR to the integration branch.
abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const language = '/language';

  /// Arguments: optional [HomeTab] (or its index) to open.
  static const home = '/home';

  /// Arguments: LessonLaunch.
  static const lesson = '/lesson';

  /// Arguments: LessonReward.
  static const complete = '/complete';

  /// Discover catalogue (also a home tab). No arguments.
  static const discover = '/discover';

  /// Arguments: [MediaLessonArgs].
  static const mediaLesson = '/media-lesson';

  /// Arguments: optional TutorContext (null = free conversation).
  static const speak = '/speak';

  /// My Words (also a home tab). No arguments.
  static const myWords = '/my-words';
}

/// Target bottom-navigation order for the hackathon MVP. Engineer 1 owns the
/// shell that renders it. Test keys are `nav_<label>`.
enum HomeTab {
  learn('Learn'),
  discover('Discover'),
  speak('Speak'),
  myWords('My Words');

  const HomeTab(this.label);
  final String label;
}

class MediaLessonArgs {
  const MediaLessonArgs(this.mediaId);
  final String mediaId;
}

/// Shared page transition: a short fade + rise. Instant under reduced motion.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
         transitionDuration: Motion.medium,
         reverseTransitionDuration: Motion.fast,
         pageBuilder: (context, _, _) => builder(context),
         transitionsBuilder: (context, anim, _, child) {
           if (Motion.reduced(context)) return child;
           final curved = CurvedAnimation(
             parent: anim,
             curve: Motion.emphasized,
           );
           return FadeTransition(
             opacity: curved,
             child: SlideTransition(
               position: Tween(
                 begin: const Offset(0, 0.04),
                 end: Offset.zero,
               ).animate(curved),
               child: child,
             ),
           );
         },
       );
}
