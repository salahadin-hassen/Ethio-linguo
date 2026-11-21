import 'package:flutter/material.dart';

import '../../core/components/entrance.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/continue_card.dart';
import 'widgets/daily_quests_card.dart';
import 'widgets/featured_media_card.dart';
import 'widgets/garden_entry_card.dart';
import 'widgets/home_header.dart';
import 'widgets/path_preview_card.dart';
import 'widgets/quick_actions.dart';

/// Dashboard: the learner's daily starting point.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<HomeTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('home_scroll'),
      slivers: [
        const SliverToBoxAdapter(child: HomeHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.lg,
            Space.gutter,
            Space.xxl,
          ),
          sliver: SliverList.list(
            children: [
              const Entrance(child: ContinueLearningCard()),
              const SizedBox(height: Space.md),
              const Entrance(
                delay: Duration(milliseconds: 40),
                child: FeaturedMediaCard(),
              ),
              const SizedBox(height: Space.md),
              Entrance(
                delay: const Duration(milliseconds: 60),
                child: QuickActions(onOpenTab: onOpenTab),
              ),
              const SizedBox(height: Space.md),
              Entrance(
                delay: const Duration(milliseconds: 80),
                child: GardenEntryCard(
                  onOpen: () => Navigator.pushNamed(context, AppRoutes.garden),
                ),
              ),
              const SizedBox(height: Space.md),
              const Entrance(
                delay: Duration(milliseconds: 140),
                child: DailyQuestsCard(),
              ),
              const SizedBox(height: Space.md),
              Entrance(
                delay: const Duration(milliseconds: 200),
                child: PathPreviewCard(
                  onSeeAll: () => onOpenTab(HomeTab.learn),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
