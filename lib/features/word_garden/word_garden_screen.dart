import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_sheet.dart';
import '../../core/components/empty_state.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/progress.dart';
import '../learning_path/node_actions.dart';
import '../lessons/lesson_launch.dart';
import '../mascot/mascot.dart';
import 'widgets/garden_plot.dart';
import 'widgets/word_plant.dart';

/// The learner's personal collection of words, growing with practice.
class WordGardenScreen extends StatelessWidget {
  const WordGardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final words = app.progress.words;
    final thirsty = app.wordsNeedingWater.toSet();
    final blooms = words.values
        .where((w) => w.stage == GrowthStage.bloom)
        .length;
    final ids = words.keys.toList()
      ..sort((a, b) {
        final t = (thirsty.contains(a) ? 0 : 1) - (thirsty.contains(b) ? 0 : 1);
        return t != 0 ? t : words[b]!.strength - words[a]!.strength;
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Word Garden')),
      body: words.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  mood: MascotMood.sleeping,
                  title: 'Your garden is waiting',
                  message: 'Each word you learn is planted here as a seed. Practise it and watch it bloom.',
                  actionLabel: 'Plant my first words',
                  onAction: () {
                    final n = app.currentNode;
                    if (n != null) openPathNode(context, n);
                  },
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.xs,
                    Space.gutter,
                    Space.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(Space.md),
                      decoration: BoxDecoration(
                        color: AppColors.tealTint,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${words.length} words growing',
                                      style: AppType.title,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      thirsty.isEmpty
                                          ? 'All watered. Come back tomorrow to keep them fresh.'
                                          : '${thirsty.length} ${thirsty.length == 1 ? 'word needs' : 'words need'} a quick review.',
                                      style: AppType.bodySmall.copyWith(
                                        color: AppColors.tealInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Mascot(
                                mood: thirsty.isEmpty
                                    ? MascotMood.happy
                                    : MascotMood.encouraging,
                                size: 84,
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.sm),
                          Row(
                            children: [
                              _Stat(label: 'Planted', value: '${words.length}'),
                              _Stat(label: 'In bloom', value: '$blooms'),
                              _Stat(
                                label: 'Thirsty',
                                value: '${thirsty.length}',
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.md),
                          AppButton(
                            key: const ValueKey('water_garden'),
                            label: thirsty.isEmpty
                                ? 'Practise anyway'
                                : 'Water your garden',
                            variant: AppButtonVariant.success,
                            icon: Icons.water_drop_rounded,
                            onPressed: () => Navigator.of(context).pushNamed(
                              AppRoutes.lesson,
                              arguments: GardenReviewLaunch(
                                app.wordsForReview(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                  sliver: SliverToBoxAdapter(child: _StageLegend()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.md,
                    Space.gutter,
                    Space.xxl,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 130,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 164,
                        ),
                    itemCount: ids.length,
                    itemBuilder: (context, i) {
                      final id = ids[i];
                      final term = app.course.terms[id];
                      final w = words[id]!;
                      final petal =
                          petalColors[app.course.terms.keys.toList().indexOf(
                                id,
                              ) %
                              petalColors.length];
                      return GardenPlot(
                        native: term?.native.of(app.native) ?? id,
                        english: term?.english ?? id,
                        word: w,
                        thirsty: thirsty.contains(id),
                        petal: petal,
                        onTap: () => _showWord(
                          context,
                          term?.native.of(app.native) ?? id,
                          term?.english ?? id,
                          w,
                          petal,
                          app.today,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showWord(
    BuildContext context,
    String native,
    String english,
    WordProgress w,
    Color petal,
    String today,
  ) {
    final days = daysBetween(w.lastPracticed, today);
    showAppSheet<void>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WordPlant(
            stage: w.stage,
            petal: petal,
            size: 120,
            thirsty: w.needsWater(today),
          ),
          const SizedBox(height: Space.sm),
          Text(native, style: AppType.display),
          Text(
            english,
            style: AppType.title.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: Space.md),
          Text(
            '${stageNames[w.stage]} · practised ${days == 0
                ? 'today'
                : days == 1
                ? 'yesterday'
                : '$days days ago'}',
            style: AppType.label.copyWith(color: AppColors.tealInk),
          ),
          const SizedBox(height: Space.lg),
          AppButton(
            label: 'Close',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: AppType.headline),
        Text(label, style: AppType.caption.copyWith(color: AppColors.tealInk)),
      ],
    ),
  );
}

class _StageLegend extends StatelessWidget {
  const _StageLegend();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Growth stages: seed, sprout, bud, bloom',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final s in GrowthStage.values)
            Column(
              children: [
                WordPlant(stage: s, size: 40),
                Text(
                  stageNames[s]!,
                  style: AppType.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
