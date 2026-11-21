import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../core/components/app_button.dart';
import '../../core/components/empty_state.dart';
import '../../core/components/progress_bar.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/support_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../mascot/mascot_mood.dart';
import '../progress/activity_reward_sheet.dart';
import 'revision_controller.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  RevisionController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c ??= RevisionController(
      services: ServicesScope.of(context),
      progress: AppScope.read(context),
    );
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _grade(bool knewIt) async {
    await _c!.grade(knewIt: knewIt);
    final r = _c!.reward;
    if (r != null && mounted) {
      await showActivityReward(
        context,
        r,
        title: 'Review complete!',
        detail: 'You remembered ${_c!.remembered} of ${_c!.queue.length}.',
      );
      if (mounted) Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListenableBuilder(
      listenable: _c!,
      builder: (context, _) {
        final c = _c!;
        final card = c.card;
        return Scaffold(
          appBar: AppBar(title: Text('Review My Words', style: AppType.title)),
          body: c.isEmpty
              ? Center(
                  child: EmptyState(
                    title: 'Nothing to review',
                    message: s.en(S.myWordsEmpty),
                    mood: MascotMood.sleeping,
                  ),
                )
              : card == null
              ? Center(
                  child: EmptyState(
                    title: 'All reviewed',
                    message:
                        'You remembered ${c.remembered} of ${c.queue.length}.',
                    mood: MascotMood.celebrating,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(Space.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppProgressBar(
                        value: c.index / c.queue.length,
                        semanticLabel:
                            'Card ${c.index + 1} of ${c.queue.length}',
                      ),
                      const SizedBox(height: Space.lg),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            key: const ValueKey('revision_card'),
                            padding: const EdgeInsets.all(Space.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: Radii.xlAll,
                              border: Border.all(
                                color: AppColors.outline,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.originalExpression,
                                  key: const ValueKey('revision_expression'),
                                  style: AppType.prompt,
                                ),
                                if (card.contextLine != null)
                                  Text(
                                    '"${card.contextLine}"',
                                    style: AppType.body.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                const SizedBox(height: Space.lg),
                                if (!c.revealed)
                                  LabelWithSupport(
                                    S.reviewQuestion,
                                    style: AppType.title,
                                  )
                                else ...[
                                  Directionality(
                                    textDirection: s.direction,
                                    child: Text(
                                      card.meaningIn(s.lang) ?? '—',
                                      key: const ValueKey('revision_meaning'),
                                      style: AppType.title.copyWith(
                                        color: AppColors.tealInk,
                                      ),
                                    ),
                                  ),
                                  if (card.example != null) ...[
                                    const SizedBox(height: Space.sm),
                                    Text(card.example!, style: AppType.body),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      if (!c.revealed)
                        AppButton(
                          key: const ValueKey('revision_reveal'),
                          label: 'Show meaning',
                          onPressed: c.reveal,
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                key: const ValueKey('revision_again'),
                                label: s.en(S.stillLearning),
                                variant: AppButtonVariant.secondary,
                                onPressed: () => _grade(false),
                              ),
                            ),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: AppButton(
                                key: const ValueKey('revision_knew'),
                                label: s.en(S.iRemembered),
                                variant: AppButtonVariant.success,
                                onPressed: () => _grade(true),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
