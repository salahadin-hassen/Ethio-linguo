import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/components/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../learning_path/node_actions.dart';
import '../../learning_path/widgets/path_node_button.dart';

/// Horizontal glimpse of the upcoming path nodes.
class PathPreviewCard extends StatelessWidget {
  const PathPreviewCard({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final nodes = app.course.allNodes;
    final current = app.currentNode;
    final start = current == null
        ? (nodes.length - 4).clamp(0, nodes.length)
        : (nodes.indexOf(current) - 1).clamp(0, nodes.length);
    final visible = nodes.skip(start).take(4).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Your path', style: AppType.title),
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  'SEE ALL',
                  style: AppType.label.copyWith(color: AppColors.periwinkleInk),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, n) in visible.indexed) ...[
                Expanded(
                  child: Column(
                    children: [
                      PathNodeButton(
                        node: n,
                        state: app.stateOf(n),
                        unitColor: app.course.unitOf(n.id).color,
                        unitShade: app.course.unitOf(n.id).shade,
                        size: 52,
                        onTap: () => openPathNode(context, n),
                      ),
                      Text(
                        n.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < visible.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 37),
                    child: Container(
                      width: 10,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
