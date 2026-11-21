import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_sheet.dart';
import '../../core/components/brand_icons.dart';
import '../../core/components/empty_state.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/conversation.dart';
import '../../data/models/language.dart';
import '../../data/models/vocabulary.dart';
import '../mascot/mascot_mood.dart';

/// Personal vocabulary library: saved expressions with context, review,
/// remove, and a door to the Word Garden (lesson vocabulary).
class MyWordsScreen extends StatelessWidget {
  const MyWordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ServicesScope.of(context).vocabulary;
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: Text('My Words', style: AppType.title),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final items = repo.all;
          final due = repo.due(app.now).length;
          return ListView(
            padding: const EdgeInsets.all(Space.gutter),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Counter(
                      label: 'Saved',
                      value: '${items.length}',
                      color: AppColors.periwinkleTint,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: _Counter(
                      label: 'Mastered',
                      value:
                          '${items.where((e) => e.masteryStatus == MasteryStatus.mastered).length}',
                      color: AppColors.tealTint,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: _Counter(
                      label: 'Garden',
                      value: '${app.progress.words.length}',
                      color: AppColors.goldTint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              if (items.isNotEmpty)
                AppButton(
                  key: const ValueKey('my_words_review'),
                  label: due > 0 ? 'Review $due due' : 'Practise all',
                  icon: Icons.style_rounded,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.revision),
                ),
              const SizedBox(height: Space.xs),
              AppButton(
                key: const ValueKey('my_words_garden'),
                label: 'Open Word Garden',
                variant: AppButtonVariant.ghost,
                icon: Icons.local_florist_rounded,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.garden),
              ),
              const SizedBox(height: Space.md),
              if (items.isEmpty)
                EmptyState(
                  title: 'No saved expressions yet',
                  message: 'Tap a highlighted phrase in a Discover video and save it.',
                  mood: MascotMood.encouraging,
                  actionLabel: 'Open Discover',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.discover),
                )
              else
                for (final e in items) ...[
                  VocabularyTile(entry: e, native: app.native, now: app.now),
                  const SizedBox(height: Space.sm),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: Space.sm),
    decoration: BoxDecoration(color: color, borderRadius: Radii.lgAll),
    child: Column(
      children: [
        Text(value, style: AppType.headline),
        Text(label, style: AppType.caption),
      ],
    ),
  );
}

class VocabularyTile extends StatelessWidget {
  const VocabularyTile({
    super.key,
    required this.entry,
    required this.native,
    required this.now,
  });

  final VocabularyEntry entry;
  final NativeLanguage native;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AppCard(
      key: ValueKey('vocab_${entry.expressionId ?? entry.id}'),
      semanticLabel: 'Open ${entry.originalExpression}',
      onTap: () => _showDetail(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.originalExpression, style: AppType.titleSmall),
                if (entry.meaningIn(native) != null)
                  Directionality(
                    textDirection: s.direction,
                    child: Text(
                      entry.meaningIn(native)!,
                      style: AppType.body.copyWith(color: AppColors.tealInk),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  '${_sourceLabel(entry)} · ${AppStrings.relativeDay(entry.createdAt.toLocal(), now)}',
                  style: AppType.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _MasteryBadge(entry.masteryStatus),
        ],
      ),
    );
  }

  static String _sourceLabel(VocabularyEntry e) => switch (e.source) {
    VocabularySource.media => 'From "${e.sourceContentTitle ?? 'video'}"',
    VocabularySource.tutor => 'From the Professor',
    VocabularySource.lesson => 'From a lesson',
  };

  void _showDetail(BuildContext context) {
    final s = AppStrings.of(context);
    final services = ServicesScope.of(context);
    showAppSheet<void>(
      context,
      builder: (ctx) => Column(
        key: const ValueKey('vocab_detail'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.originalExpression, style: AppType.prompt),
          if (entry.meaningIn(native) != null)
            Text(
              entry.meaningIn(native)!,
              style: AppType.title.copyWith(color: AppColors.tealInk),
            ),
          if (entry.contextualMeaning[native.code] != null) ...[
            const SizedBox(height: Space.sm),
            Text(s.en(S.inThisScene), style: AppType.overline),
            Text(entry.contextualMeaning[native.code]!, style: AppType.body),
          ],
          if (entry.contextLine != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              '"${entry.contextLine}"',
              style: AppType.body.copyWith(fontStyle: FontStyle.italic),
            ),
            if (entry.contextTranslations[native.code] != null)
              Text(
                entry.contextTranslations[native.code]!,
                style: AppType.bodySmall.copyWith(color: AppColors.textMuted),
              ),
          ],
          if (entry.example != null) ...[
            const SizedBox(height: Space.sm),
            Text(s.en(S.example), style: AppType.overline),
            Text(entry.example!, style: AppType.body),
          ],
          const SizedBox(height: Space.sm),
          Text(
            'Saved ${AppStrings.relativeDay(entry.createdAt.toLocal(), now)} · '
            'reviewed ${entry.reviewCount}×',
            style: AppType.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: Space.md),
          if (services.speechOut.available)
            AppButton(
              label: s.en(S.listen),
              icon: Icons.volume_up_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => services.speechOut.speak(
                entry.originalExpression,
                localeId: Languages.en.speechLocale!,
              ),
            ),
          const SizedBox(height: Space.xs),
          AppButton(
            key: const ValueKey('vocab_practise'),
            label: s.en(S.practiseWithProfessor),
            icon: Icons.record_voice_over_rounded,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(
                context,
                AppRoutes.speak,
                arguments: TutorContext(
                  native: native,
                  level: AppScope.read(context).profile.level,
                  focusExpression: entry.originalExpression,
                  targetExpressions: [entry.originalExpression],
                ),
              );
            },
          ),
          const SizedBox(height: Space.xs),
          AppButton(
            key: const ValueKey('vocab_remove'),
            label: s.en(S.remove),
            icon: Icons.delete_outline_rounded,
            variant: AppButtonVariant.ghost,
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = services.vocabulary;
              await repo.remove(entry.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${entry.originalExpression}"'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => repo.save(entry),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MasteryBadge extends StatelessWidget {
  const _MasteryBadge(this.status);
  final MasteryStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      MasteryStatus.learning => (
        'Learning',
        AppColors.coralTint,
        BrandIconKind.leaf,
      ),
      MasteryStatus.familiar => (
        'Familiar',
        AppColors.goldTint,
        BrandIconKind.star,
      ),
      MasteryStatus.mastered => (
        'Mastered',
        AppColors.tealTint,
        BrandIconKind.crown,
      ),
    };
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandIcon(icon, size: 14),
            const SizedBox(width: 4),
            Text(label, style: AppType.caption),
          ],
        ),
      ),
    );
  }
}
