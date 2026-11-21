import 'package:flutter/material.dart';

import '../../../core/components/app_button.dart';
import '../../../core/components/brand_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/language.dart';
import '../../mascot/mascot.dart';
import '../logic/answer_validator.dart';

/// Slide-up result panel. Mistakes are framed as learning moments.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.verdict,
    required this.solution,
    required this.native,
    required this.onContinue,
    required this.heartLost,
    required this.practiceMode,
    required this.willRetry,
    this.run = 0,
  });

  final Verdict verdict;
  final String solution;
  final NativeLanguage native;
  final VoidCallback onContinue;
  final bool heartLost;
  final bool practiceMode;
  final bool willRetry;
  final int run;

  static const _praise = {
    NativeLanguage.amharic: 'ጎበዝ!',
    NativeLanguage.oromo: "Baay'ee gaarii!",
  };

  @override
  Widget build(BuildContext context) {
    final good = verdict != Verdict.incorrect;
    final bg = good ? AppColors.tealTint : AppColors.coralTint;
    final ink = good ? AppColors.tealInk : AppColors.coralInk;
    final title = switch (verdict) {
      Verdict.correct =>
        run >= 3
            ? '$run in a row! ${_praise[native]}'
            : 'Nice work! ${_praise[native]}',
      Verdict.almost => 'Almost! Check the spelling',
      Verdict.incorrect => "Not quite — that's how we learn",
    };
    final detail = switch (verdict) {
      Verdict.correct => null,
      Verdict.almost => 'Correct spelling: $solution',
      Verdict.incorrect => 'Correct answer: $solution',
    };
    return Semantics(
      liveRegion: true,
      container: true,
      label: '$title. ${detail ?? ''}',
      child: Container(
        key: const ValueKey('feedback_panel'),
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.md,
          Space.gutter,
          Space.md,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CharacterAvatar(
                    character: CastMember.spark,
                    state: good
                        ? CharacterState.happy
                        : CharacterState.encouraging,
                    size: 64,
                    reactOnMount: true,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppType.title.copyWith(color: ink),
                          ),
                          if (detail != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              detail,
                              style: AppType.body.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          if (!good) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (heartLost)
                                  const _Chip(
                                    icon: BrandIconKind.heart,
                                    text: '−1 heart',
                                  ),
                                if (practiceMode)
                                  const _Chip(
                                    icon: BrandIconKind.leaf,
                                    text: 'Practice mode: no hearts lost',
                                  ),
                                if (willRetry)
                                  const _Chip(
                                    icon: BrandIconKind.star,
                                    text: "You'll see this again",
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              AppButton(
                key: const ValueKey('continue_button'),
                label: good ? 'Continue' : 'Got it',
                variant: good
                    ? AppButtonVariant.success
                    : AppButtonVariant.danger,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final BrandIconKind icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandIcon(icon, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppType.caption.copyWith(color: AppColors.coralInk),
          ),
        ),
      ],
    ),
  );
}
