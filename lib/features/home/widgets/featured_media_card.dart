import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_services.dart';
import '../../../core/components/app_card.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/content.dart';

/// The first catalogue item as the dashboard's featured scene. Renders
/// nothing if no content is installed (no fake placeholder).
class FeaturedMediaCard extends StatefulWidget {
  const FeaturedMediaCard({super.key});

  @override
  State<FeaturedMediaCard> createState() => _FeaturedMediaCardState();
}

class _FeaturedMediaCardState extends State<FeaturedMediaCard> {
  Future<List<LearningContent>>? _list;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _list ??= ServicesScope.of(context).content.list();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = AppStrings.of(context);
    return FutureBuilder(
      future: _list,
      builder: (context, snap) {
        final items = snap.data;
        if (items == null || items.isEmpty) return const SizedBox.shrink();
        final c = items.first;
        final done = app.hasCompleted('media:${c.id}');
        return AppCard(
          key: const ValueKey('home_featured_media'),
          padding: EdgeInsets.zero,
          color: AppColors.indigo,
          borderColor: AppColors.indigo,
          semanticLabel: 'Featured scene: ${c.title}',
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.mediaLesson,
            arguments: MediaLessonArgs(c.id),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(Radii.md),
                ),
                child: SizedBox(
                  width: 128,
                  height: 96,
                  child: c.media.posterAsset == null
                      ? const ColoredBox(color: AppColors.indigoRaised)
                      : Image.asset(c.media.posterAsset!, fit: BoxFit.cover),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.en(S.watchAndLearn).toUpperCase(),
                        style: AppType.overline.copyWith(color: AppColors.gold),
                      ),
                      Text(
                        c.title,
                        style: AppType.titleSmall.copyWith(
                          color: AppColors.ivory,
                        ),
                      ),
                      Text(
                        done
                            ? 'Completed · watch again'
                            : '${(c.durationMs / 1000).round()}s scene · '
                                  'subtitles in ${app.native.englishName}',
                        style: AppType.caption.copyWith(
                          color: AppColors.onIndigoMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: Space.sm),
                child: Icon(
                  done ? Icons.check_circle_rounded : Icons.play_circle_rounded,
                  color: done ? AppColors.teal : AppColors.coral,
                  size: 36,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
