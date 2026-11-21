import 'package:flutter/material.dart';

import '../../core/components/empty_state.dart';
import '../mascot/mascot_mood.dart';

/// OWNER: Engineer 2 (feat/media-learning). Placeholder until the media
/// catalogue lands. Lists MediaItems from ServicesScope.of(context).media and
/// opens AppRoutes.mediaLesson with MediaLessonArgs.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: EmptyState(
          title: 'Discover',
          message: 'Short clips to learn from are on the way.',
          mood: MascotMood.thinking,
        ),
      ),
    );
  }
}
