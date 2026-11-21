import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/components/app_card.dart';
import '../../core/components/empty_state.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/support_text.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/content.dart';
import '../../data/repositories/content_repository.dart';
import '../mascot/mascot_mood.dart';

/// Content catalogue. Works as a tab (no back button) and as a route.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late Future<List<(LearningContent, DownloadState)>> _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ServicesScope.of(context);
    _items = _load(s);
  }

  // Sequential awaits (not Future.wait): repositories may return
  // SynchronousFutures, which Future.wait does not support.
  static Future<List<(LearningContent, DownloadState)>> _load(
    AppServices s,
  ) async => [
    for (final c in await s.content.list()) (c, await s.downloads.stateOf(c)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: Text('Discover', style: AppType.title),
      ),
      body: FutureBuilder(
        future: _items,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const [];
          if (snap.hasError || items.isEmpty) {
            return const Center(
              child: EmptyState(
                title: 'Nothing to watch yet',
                message: 'Content packages will appear here.',
                mood: MascotMood.thinking,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(Space.gutter),
            children: [
              LabelWithSupport(
                S.watchAndLearn,
                style: AppType.headline,
                supportStyle: AppType.body.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: Space.xxs),
              Text(
                'Short real-life scenes with subtitles in your language.',
                style: AppType.body.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: Space.md),
              for (final (c, d) in items) ...[
                ContentCard(content: c, download: d),
                const SizedBox(height: Space.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.content, required this.download});

  final LearningContent content;
  final DownloadState download;

  @override
  Widget build(BuildContext context) {
    final secs = (content.durationMs / 1000).round();
    return AppCard(
      key: ValueKey('content_${content.id}'),
      padding: EdgeInsets.zero,
      semanticLabel: 'Open lesson ${content.title}',
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.mediaLesson,
        arguments: MediaLessonArgs(content.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Radii.md),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (content.media.posterAsset != null)
                    Image.asset(content.media.posterAsset!, fit: BoxFit.cover)
                  else
                    const ColoredBox(color: AppColors.indigo),
                  const Center(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.coral,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.indigo,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content.title, style: AppType.title),
                const SizedBox(height: 2),
                Text(
                  content.description,
                  style: AppType.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    _Tag('${secs}s', Icons.schedule_rounded),
                    _Tag(
                      _level(content.difficulty),
                      Icons.signal_cellular_alt_rounded,
                    ),
                    if (download == DownloadState.bundled)
                      const _Tag('Works offline', Icons.offline_pin_rounded),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text(
                  content.rights.licenseType == 'original'
                      ? 'Original content'
                      : 'License: ${content.rights.licenseType}',
                  style: AppType.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _level(int d) => switch (d) {
    1 => 'Beginner',
    2 => 'Elementary',
    _ => 'Intermediate',
  };
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.icon);
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceSunken,
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: AppType.caption),
      ],
    ),
  );
}
