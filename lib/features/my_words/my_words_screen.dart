import 'package:flutter/material.dart';

import '../../core/components/empty_state.dart';
import '../mascot/mascot_mood.dart';

/// OWNER: Engineer 1 (feat/mobile-ui). Saved expressions from
/// ServicesScope.of(context).vocabulary (listen to it: it is a
/// ChangeNotifier) plus the existing Word Garden.
class MyWordsScreen extends StatelessWidget {
  const MyWordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: EmptyState(
          title: 'My Words',
          message:
              'Expressions you save from clips and conversations live here.',
          mood: MascotMood.happy,
        ),
      ),
    );
  }
}
