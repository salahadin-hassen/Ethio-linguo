import 'package:flutter/material.dart';

import '../../core/components/empty_state.dart';
import '../../core/navigation/app_routes.dart';
import '../mascot/mascot_mood.dart';

/// OWNER: Engineer 2 (feat/media-learning). Video + synchronised English and
/// native-language subtitles, tappable expressions, save to My Words, then
/// AppController.recordActivity and an offer to practise in Speak.
class MediaLessonScreen extends StatelessWidget {
  const MediaLessonScreen({super.key, required this.args});

  final MediaLessonArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: EmptyState(
          title: 'Media lesson',
          message: 'Clip "${args.mediaId}" is not built yet.',
          mood: MascotMood.thinking,
        ),
      ),
    );
  }
}
