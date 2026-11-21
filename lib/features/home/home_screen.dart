import 'package:flutter/material.dart';

import '../../core/components/entrance.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/continue_card.dart';
import 'widgets/daily_quests_card.dart';
import 'widgets/garden_entry_card.dart';
import 'widgets/home_header.dart';
import 'widgets/path_preview_card.dart';

/// Dashboard: the learner's daily starting point.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

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
              Entrance(
                delay: const Duration(milliseconds: 80),
                child: GardenEntryCard(onOpen: () => onOpenTab(2)),
              ),
              const SizedBox(height: Space.md),
              const Entrance(
                delay: Duration(milliseconds: 140),
                child: DailyQuestsCard(),
              ),
              const SizedBox(height: Space.md),
              Entrance(
                delay: const Duration(milliseconds: 200),
                child: PathPreviewCard(onSeeAll: () => onOpenTab(1)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
