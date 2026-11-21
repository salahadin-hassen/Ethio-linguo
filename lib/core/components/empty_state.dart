import 'package:flutter/material.dart';

import '../../features/mascot/mascot.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Friendly empty / error state: mascot + message + optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.mood = MascotMood.sleeping,
    this.actionLabel,
    this.onAction,
    this.mascotSize = 140,
  });

  final String title;
  final String message;
  final MascotMood mood;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double mascotSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Mascot(mood: mood, size: mascotSize),
          const SizedBox(height: Space.md),
          Text(title, textAlign: TextAlign.center, style: AppType.title),
          const SizedBox(height: Space.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppType.body.copyWith(color: AppColors.textMuted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: Space.lg),
            AppButton(label: actionLabel!, onPressed: onAction, expand: false),
          ],
        ],
      ),
    );
  }
}
