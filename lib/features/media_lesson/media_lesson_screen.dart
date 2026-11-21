import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../core/components/app_button.dart';
import '../../core/components/empty_state.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/motion/motion.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/content.dart';
import '../../data/models/transcript.dart';
import '../../services/playback/media_playback.dart';
import '../mascot/mascot_mood.dart';
import '../progress/activity_reward_sheet.dart';
import 'media_lesson_controller.dart';
import 'widgets/expression_sheet.dart';

/// Scene-to-speech lesson: video, synced bilingual subtitles, tappable
/// expressions, transcript, completion. Logic lives in the controller.
class MediaLessonScreen extends StatefulWidget {
  const MediaLessonScreen({super.key, required this.args});

  final MediaLessonArgs args;

  @override
  State<MediaLessonScreen> createState() => _MediaLessonScreenState();
}

class _MediaLessonScreenState extends State<MediaLessonScreen> {
  MediaLessonController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c ??= MediaLessonController(
      contentId: widget.args.contentId,
      services: ServicesScope.of(context),
      progress: AppScope.read(context),
    )..load();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _openExpression(Expression e) async {
    final c = _c!;
    await c.onExpressionSelected(e);
    if (!mounted) return;
    await showExpressionSheet(
      context,
      expression: e,
      segment: c.transcript!.segmentById(e.segmentId)!,
      native: c.native,
      translationInfo: c.content!.translationInfo(c.native),
      isSaved: () => c.isSaved(e),
      onSave: () => c.save(e),
      onReplayLine: () => c.replay(c.transcript!.segmentById(e.segmentId)),
      onPractise: () => Navigator.pushNamed(
        context,
        AppRoutes.speak,
        arguments: c.tutorContext(focus: e),
      ),
    );
    c.clearSelection();
  }

  Future<void> _finish() async {
    final c = _c!;
    final reward = await c.finish();
    if (!mounted) return;
    await showActivityReward(
      context,
      reward,
      title: 'Scene complete!',
      detail: 'You watched "${c.content!.title}".',
      primaryLabel: AppStrings.of(context).en(S.practiseWithProfessor),
      onPrimary: () => Navigator.pushNamed(
        context,
        AppRoutes.speak,
        arguments: c.tutorContext(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c!,
      builder: (context, _) {
        final c = _c!;
        return Scaffold(
          appBar: AppBar(
            title: Text(c.content?.title ?? 'Lesson', style: AppType.title),
            actions: [
              if (c.phase == MediaLessonPhase.ready)
                IconButton(
                  key: const ValueKey('media_toggle_translation'),
                  tooltip: c.showTranslation
                      ? 'Hide translation'
                      : 'Show translation',
                  onPressed: c.toggleTranslation,
                  icon: Icon(
                    c.showTranslation
                        ? Icons.translate_rounded
                        : Icons.g_translate_outlined,
                  ),
                ),
            ],
          ),
          body: switch (c.phase) {
            MediaLessonPhase.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            MediaLessonPhase.error => Center(
              child: EmptyState(
                title: 'Lesson unavailable',
                message: c.error ?? 'Something went wrong.',
                mood: MascotMood.confused,
                actionLabel: 'Back',
                onAction: () => Navigator.maybePop(context),
              ),
            ),
            MediaLessonPhase.ready => _Ready(
              c: c,
              onExpression: _openExpression,
              onFinish: _finish,
            ),
          },
        );
      },
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.c,
    required this.onExpression,
    required this.onFinish,
  });

  final MediaLessonController c;
  final ValueChanged<Expression> onExpression;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final t = c.transcript!;
    return Column(
      children: [
        _VideoArea(c: c),
        _SubtitlePanel(c: c, onExpression: onExpression),
        _Controls(c: c),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('media_transcript'),
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.sm,
              Space.gutter,
              Space.lg,
            ),
            itemCount: t.segments.length + 1,
            itemBuilder: (context, i) {
              if (i == t.segments.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: Space.md),
                  child: AppButton(
                    key: const ValueKey('media_finish'),
                    label: c.completed ? 'Finish lesson' : 'Finish early',
                    variant: c.completed
                        ? AppButtonVariant.success
                        : AppButtonVariant.secondary,
                    onPressed: onFinish,
                  ),
                );
              }
              return _TranscriptRow(
                c: c,
                segment: t.segments[i],
                onExpression: onExpression,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VideoArea extends StatelessWidget {
  const _VideoArea({required this.c});
  final MediaLessonController c;

  @override
  Widget build(BuildContext context) {
    final p = c.playback!;
    return ValueListenableBuilder<PlaybackState>(
      valueListenable: p.state,
      builder: (context, s, _) {
        final view = p.buildView();
        return Container(
          color: AppColors.indigo,
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (view != null)
                  Center(child: view)
                else if (c.content!.media.posterAsset != null)
                  Image.asset(
                    c.content!.media.posterAsset!,
                    fit: BoxFit.cover,
                    semanticLabel: 'Scene illustration',
                  ),
                if (view == null && !platformHasVideo)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.all(Space.xs),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withValues(alpha: 0.85),
                        borderRadius: Radii.smAll,
                      ),
                      child: Text(
                        'Video playback is not supported on this desktop '
                        'build. Subtitles follow a timer.',
                        style: AppType.caption.copyWith(color: AppColors.ivory),
                      ),
                    ),
                  ),
                if (!s.playing)
                  Center(
                    child: IconButton.filled(
                      key: const ValueKey('media_big_play'),
                      iconSize: 44,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: AppColors.indigo,
                      ),
                      tooltip: 'Play',
                      onPressed: c.togglePlay,
                      icon: Icon(
                        s.completed
                            ? Icons.replay_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubtitlePanel extends StatelessWidget {
  const _SubtitlePanel({required this.c, required this.onExpression});
  final MediaLessonController c;
  final ValueChanged<Expression> onExpression;

  @override
  Widget build(BuildContext context) {
    final seg = c.current;
    final s = AppStrings.of(context);
    final translation = seg?.translationIn(c.native);
    return Container(
      key: const ValueKey('media_subtitles'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      color: AppColors.indigoRaised,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.gutter,
        vertical: Space.sm,
      ),
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.feedback),
        switchInCurve: Motion.emphasized,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(a),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(seg?.id),
          child: seg == null
              ? Center(
                  child: Text(
                    s.en(S.tapPhraseHint),
                    style: AppType.bodySmall.copyWith(
                      color: AppColors.onIndigoMuted,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedLine(
                      key: const ValueKey('subtitle_en'),
                      line: seg.originalText,
                      expressions: c.transcript!.expressionsIn(seg),
                      style: AppType.title.copyWith(color: AppColors.ivory),
                      onExpression: onExpression,
                      selected: c.selected,
                    ),
                    if (c.showTranslation && translation != null) ...[
                      const SizedBox(height: 4),
                      Directionality(
                        textDirection: s.direction,
                        child: Text(
                          translation,
                          key: const ValueKey('subtitle_native'),
                          style: AppType.body.copyWith(
                            color: AppColors.onIndigoMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Renders a line with tappable, gold-underlined expressions.
class _HighlightedLine extends StatefulWidget {
  const _HighlightedLine({
    super.key,
    required this.line,
    required this.expressions,
    required this.style,
    required this.onExpression,
    this.highlight = AppColors.gold,
    this.selected,
  });

  final Color highlight;
  final Expression? selected;
  final String line;
  final List<Expression> expressions;
  final TextStyle style;
  final ValueChanged<Expression> onExpression;

  @override
  State<_HighlightedLine> createState() => _HighlightedLineState();
}

class _HighlightedLineState extends State<_HighlightedLine> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final spans = spansFor(widget.line, widget.expressions);
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (final s in spans)
            if (s.expression == null)
              TextSpan(text: s.text)
            else
              TextSpan(
                text: s.text,
                semanticsLabel: '${s.text}, tap to learn',
                style: TextStyle(
                  backgroundColor: identical(s.expression, widget.selected)
                      ? AppColors.gold
                      : null,
                  color: identical(s.expression, widget.selected)
                      ? AppColors.indigo
                      : widget.highlight,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                  decorationColor: widget.highlight,
                  decorationThickness: 2,
                ),
                recognizer:
                    (TapGestureRecognizer()
                          ..onTap = () => widget.onExpression(s.expression!))
                        .also(_recognizers.add),
              ),
        ],
      ),
    );
  }
}

extension<T> on T {
  T also(void Function(T) f) {
    f(this);
    return this;
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.c});
  final MediaLessonController c;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlaybackState>(
      valueListenable: c.playback!.state,
      builder: (context, s, _) {
        final dur = s.durationMs == 0 ? c.content!.durationMs : s.durationMs;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xs),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('media_prev'),
                tooltip: 'Previous line',
                onPressed: () => c.step(-1),
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              IconButton(
                key: const ValueKey('media_play'),
                tooltip: s.playing ? 'Pause' : 'Play',
                onPressed: c.togglePlay,
                icon: Icon(
                  s.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
              IconButton(
                key: const ValueKey('media_replay_line'),
                tooltip: AppStrings.of(context).en(S.replayLine),
                onPressed: () => c.replay(),
                icon: const Icon(Icons.replay_rounded),
              ),
              IconButton(
                key: const ValueKey('media_next'),
                tooltip: 'Next line',
                onPressed: () => c.step(1),
                icon: const Icon(Icons.skip_next_rounded),
              ),
              Expanded(
                child: Slider(
                  value: s.positionMs.clamp(0, dur).toDouble(),
                  max: dur.toDouble(),
                  onChanged: (v) => c.playback!.seekTo(v.round()),
                  semanticFormatterCallback: (v) =>
                      '${(v / 1000).round()} of ${(dur / 1000).round()} seconds',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TranscriptRow extends StatelessWidget {
  const _TranscriptRow({
    required this.c,
    required this.segment,
    required this.onExpression,
  });

  final MediaLessonController c;
  final TranscriptSegment segment;
  final ValueChanged<Expression> onExpression;

  @override
  Widget build(BuildContext context) {
    final active = identical(c.current, segment);
    final speaker = c.content!.speakers[segment.speakerId] ?? '';
    final translation = segment.translationIn(c.native);
    final s = AppStrings.of(context);
    return Semantics(
      button: true,
      label: 'Play line: ${segment.originalText}',
      child: InkWell(
        key: ValueKey('transcript_${segment.id}'),
        borderRadius: Radii.mdAll,
        onTap: () => c.replay(segment),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: Space.xs),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: active ? AppColors.periwinkleTint : AppColors.surface,
            borderRadius: Radii.mdAll,
            border: Border.all(
              color: active ? AppColors.periwinkle : AppColors.outline,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                speaker.toUpperCase(),
                style: AppType.overline.copyWith(color: AppColors.textMuted),
              ),
              _HighlightedLine(
                line: segment.originalText,
                expressions: c.transcript!.expressionsIn(segment),
                style: AppType.body.copyWith(color: AppColors.indigo),
                highlight: AppColors.goldInk,
                onExpression: onExpression,
                selected: c.selected,
              ),
              if (c.showTranslation && translation != null)
                Directionality(
                  textDirection: s.direction,
                  child: Text(
                    translation,
                    style: AppType.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
