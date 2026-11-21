import 'package:flutter/material.dart';

import '../motion/motion.dart';

abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const language = '/language';
  static const home = '/home';
  static const lesson = '/lesson';
  static const complete = '/complete';
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
