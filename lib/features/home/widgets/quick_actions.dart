import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_services.dart';
import '../../../core/components/app_card.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Entry points to the four product areas beyond the path. Every tile
/// navigates somewhere real; counts come from repositories.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.onOpenTab});

  final ValueChanged<HomeTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final vocab = ServicesScope.of(context).vocabulary;
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: vocab,
      builder: (context, _) {
        final saved = vocab.all.length;
        final due = vocab.due(app.now).length;
        final badges = app.achievements.where((a) => a.unlocked).length;
        final tiles = [
          _Tile(
            k: 'home_discover',
            icon: Icons.smart_display_rounded,
            title: 'Discover',
            subtitle: 'Learn from scenes',
            tint: AppColors.periwinkleTint,
            onTap: () => onOpenTab(HomeTab.discover),
          ),
          _Tile(
            k: 'home_speak',
            icon: Icons.record_voice_over_rounded,
            title: 'Professor',
            subtitle: 'Speak out loud',
            tint: AppColors.coralTint,
            onTap: () => onOpenTab(HomeTab.speak),
          ),
          _Tile(
            k: 'home_my_words',
            icon: Icons.bookmark_rounded,
            title: 'My Words',
            subtitle: saved == 0
                ? 'Nothing saved yet'
                : '$saved saved${due > 0 ? ' · $due to review' : ''}',
            tint: AppColors.tealTint,
            onTap: () => onOpenTab(HomeTab.myWords),
          ),
          _Tile(
            k: 'home_badges',
            icon: Icons.emoji_events_rounded,
            title: 'Badges',
            subtitle: '$badges of ${app.achievements.length} earned',
            tint: AppColors.goldTint,
            onTap: () => Navigator.pushNamed(context, AppRoutes.achievements),
          ),
        ];
        return LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - Space.sm) / 2;
            return Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [for (final t in tiles) SizedBox(width: w, child: t)],
            );
          },
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.k,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  final String k;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    key: ValueKey(k),
    color: tint,
    borderColor: tint,
    padding: const EdgeInsets.all(Space.sm),
    semanticLabel: '$title. $subtitle',
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.indigo),
        const SizedBox(height: Space.xxs),
        Text(title, style: AppType.label),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppType.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    ),
  );
}
