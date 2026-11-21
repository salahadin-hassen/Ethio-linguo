import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_services.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_sheet.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/support_text.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/content.dart';
import '../../../data/models/language.dart';
import '../../../data/models/transcript.dart';
import '../../../services/audio/sound_effects.dart';
import '../../../services/tutor/explanation_provider.dart';

/// Contextual phrase card: expression, translation, meaning in this scene,
/// example, pronunciation (clip replay + TTS when available), save, practise.
Future<void> showExpressionSheet(
  BuildContext context, {
  required Expression expression,
  required TranscriptSegment segment,
  required NativeLanguage native,
  required TranslationInfo? translationInfo,
  required bool Function() isSaved,
  required Future<void> Function() onSave,
  required VoidCallback onReplayLine,
  required VoidCallback onPractise,
}) {
  final services = ServicesScope.of(context);
  return showAppSheet<void>(
    context,
    builder: (ctx) => FutureBuilder<ContextualExplanation>(
      future: services.explanations.explain(expression, native),
      builder: (ctx, snap) {
        final x = snap.data;
        if (x == null) {
          return const Padding(
            padding: EdgeInsets.all(Space.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _ExpressionCard(
          x: x,
          segment: segment,
          native: native,
          draft: !(translationInfo?.isReviewed ?? false),
          isSaved: isSaved,
          onSave: onSave,
          onReplayLine: () {
            Navigator.pop(ctx);
            onReplayLine();
          },
          onPractise: () {
            Navigator.pop(ctx);
            onPractise();
          },
        );
      },
    ),
  );
}

class _ExpressionCard extends StatefulWidget {
  const _ExpressionCard({
    required this.x,
    required this.segment,
    required this.native,
    required this.draft,
    required this.isSaved,
    required this.onSave,
    required this.onReplayLine,
    required this.onPractise,
  });

  final ContextualExplanation x;
  final TranscriptSegment segment;
  final NativeLanguage native;
  final bool draft;
  final bool Function() isSaved;
  final Future<void> Function() onSave;
  final VoidCallback onReplayLine;
  final VoidCallback onPractise;

  @override
  State<_ExpressionCard> createState() => _ExpressionCardState();
}

class _ExpressionCardState extends State<_ExpressionCard> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final x = widget.x;
    final services = ServicesScope.of(context);
    final saved = widget.isSaved();
    final s = AppStrings.of(context);
    final canSpeak = services.speechOut.available;
    return Column(
      key: const ValueKey('expression_sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                x.expression,
                key: const ValueKey('expression_title'),
                style: AppType.prompt,
              ),
            ),
            if (widget.draft)
              Tooltip(
                message:
                    'Written by the team, waiting for a native-speaker review',
                child: Chip(
                  label: Text(s.en(S.draftTranslation), style: AppType.caption),
                  backgroundColor: AppColors.goldTint,
                  side: BorderSide.none,
                ),
              ),
          ],
        ),
        if (x.meaning != null)
          Directionality(
            textDirection: s.direction,
            child: Text(
              x.meaning!,
              key: const ValueKey('expression_meaning'),
              style: AppType.title.copyWith(color: AppColors.tealInk),
            ),
          ),
        const SizedBox(height: Space.md),
        _Section(
          label: S.inThisScene,
          children: [
            Text(
              '"${widget.segment.originalText}"',
              style: AppType.body.copyWith(fontStyle: FontStyle.italic),
            ),
            if (x.inContext != null) ...[
              const SizedBox(height: Space.xs),
              Directionality(
                textDirection: s.direction,
                child: Text(
                  x.inContext!,
                  key: const ValueKey('expression_context'),
                  style: AppType.body,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Space.sm),
        _Section(
          label: S.example,
          children: [
            Text(x.example, style: AppType.body),
            if (x.exampleTranslation != null)
              Directionality(
                textDirection: s.direction,
                child: Text(
                  x.exampleTranslation!,
                  style: AppType.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        // Pronunciation support: the real voice from the clip always works
        // offline; device TTS is offered only where it is available.
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('expression_replay'),
              onPressed: widget.onReplayLine,
              icon: const Icon(Icons.replay_rounded),
              label: Text(s.en(S.replayLine)),
            ),
            if (canSpeak)
              OutlinedButton.icon(
                key: const ValueKey('expression_listen'),
                onPressed: () => services.speechOut.speak(
                  x.expression,
                  localeId: Languages.en.speechLocale!,
                ),
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(s.en(S.listen)),
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.reaction),
          switchInCurve: Motion.spring,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: saved
              ? Padding(
                  key: const ValueKey('expression_saved_badge'),
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: ListenableBuilder(
                    listenable: services.vocabulary,
                    builder: (context, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bookmark_added_rounded,
                          color: AppColors.tealInk,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${services.vocabulary.all.length} in My Words',
                          style: AppType.label.copyWith(
                            color: AppColors.tealInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        AppButton(
          key: const ValueKey('expression_save'),
          label: saved ? s.en(S.saved) : s.en(S.saveToMyWords),
          icon: saved ? Icons.check_rounded : Icons.bookmark_add_rounded,
          variant: saved ? AppButtonVariant.success : AppButtonVariant.primary,
          onPressed: saved || _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave();
                  if (!mounted) return;
                  // Feedback only once the save really happened.
                  if (widget.isSaved()) {
                    HapticFeedback.lightImpact();
                    services.sounds.play(Sfx.save);
                  }
                  setState(() => _saving = false);
                },
        ),
        const SizedBox(height: Space.xs),
        AppButton(
          key: const ValueKey('expression_practise'),
          label: s.en(S.practiseWithProfessor),
          icon: Icons.record_voice_over_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: widget.onPractise,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});
  final S label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Space.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: Radii.mdAll,
      border: Border.all(color: AppColors.outline, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelWithSupport(
          label,
          style: AppType.overline.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: Space.xxs),
        ...children,
      ],
    ),
  );
}
