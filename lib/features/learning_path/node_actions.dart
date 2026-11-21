import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/components/app_sheet.dart';
import '../../core/components/empty_state.dart';
import '../../core/navigation/app_routes.dart';
import '../../data/models/course.dart';
import '../lessons/lesson_launch.dart';
import '../mascot/mascot.dart';

/// Shared behaviour when a path node is tapped anywhere in the app.
void openPathNode(BuildContext context, PathNode node) {
  final app = AppScope.read(context);
  final state = app.stateOf(node);
  final messenger = ScaffoldMessenger.of(context);
  if (state == NodeState.locked) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Locked — finish "${app.currentNode?.title ?? 'the current lesson'}" first.',
          ),
        ),
      );
    return;
  }
  if (!node.hasContent) {
    showAppSheet<void>(
      context,
      builder: (ctx) => EmptyState(
        mood: MascotMood.thinking,
        title: '"${node.title}" is still being written',
        message: 'This lesson arrives in a future update. Keep your streak alive by reviewing words in your Word Garden.',
        actionLabel: 'Got it',
        onAction: () => Navigator.of(ctx).pop(),
      ),
    );
    return;
  }
  Navigator.of(context)
      .pushNamed(AppRoutes.lesson, arguments: NodeLaunch(node.id));
}
