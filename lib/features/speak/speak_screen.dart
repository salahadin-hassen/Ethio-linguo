import 'package:flutter/material.dart';

import '../../core/components/empty_state.dart';
import '../../services/tutor/tutor_service.dart';
import '../mascot/mascot_mood.dart';

/// OWNER: Engineer 3 (feat/ai-tutor). Professor conversation driven by a
/// TutorSession from ServicesScope.of(context).tutor. Must render every
/// TutorState, including the honest `unavailable` fallback.
class SpeakScreen extends StatelessWidget {
  const SpeakScreen({super.key, this.tutorContext});

  /// Null means free conversation (opened from the tab, not a lesson).
  final TutorContext? tutorContext;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: EmptyState(
          title: 'Speak',
          message: 'The Professor is not connected in this build yet.',
          mood: MascotMood.sleeping,
        ),
      ),
    );
  }
}
