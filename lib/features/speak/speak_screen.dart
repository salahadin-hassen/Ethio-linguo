import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_sheet.dart';
import '../../core/components/speech_bubble.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/support_text.dart';
import '../../core/motion/motion.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/conversation.dart';
import '../mascot/mascot.dart';
import '../progress/activity_reward_sheet.dart';
import 'tutor_session_controller.dart';

/// The Professor: a live, teaching voice conversation. Works as a tab
/// (free conversation) or as a route with a lesson [TutorContext].
class SpeakScreen extends StatefulWidget {
  const SpeakScreen({super.key, this.tutorContext});

  final TutorContext? tutorContext;

  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> {
  TutorSessionController? _c;
  final _text = TextEditingController();

  void _startSession() {
    final app = AppScope.read(context);
    _c?.dispose();
    setState(() {
      _c = TutorSessionController(
        context:
            widget.tutorContext ??
            TutorContext(
              native: app.native,
              level: app.profile.level,
              targetExpressions: const [
                'How have you been?',
                'What about you?',
                'See you soon',
              ],
            ),
        services: ServicesScope.of(context),
        progress: app,
      )..start();
    });
  }

  @override
  void dispose() {
    _c?.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _end() async {
    final c = _c!;
    final reward = await c.end();
    if (!mounted) return;
    await _showSummary(c);
    if (!mounted || reward == null) return;
    await showActivityReward(
      context,
      reward,
      title: 'Great conversation!',
      detail: 'You spoke ${c.learnerTurns} times in English.',
    );
  }

  Future<void> _showSummary(TutorSessionController c) => showAppSheet<void>(
    context,
    builder: (ctx) => ListenableBuilder(
      listenable: c,
      builder: (ctx, _) => Column(
        key: const ValueKey('speak_summary'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Session summary', style: AppType.headline),
          const SizedBox(height: Space.sm),
          _SummaryRow(
            Icons.record_voice_over_rounded,
            'English turns',
            '${c.learnerTurns}',
          ),
          _SummaryRow(
            Icons.hearing_rounded,
            'Repeat drills passed',
            '${c.repeatsPassed} of ${c.repeatsTried}',
          ),
          _SummaryRow(
            Icons.star_rounded,
            'Expressions used',
            c.usedExpressions.isEmpty ? '—' : c.usedExpressions.join(', '),
          ),
          if (c.learnerTurns < TutorSessionController.minLearnerTurnsForXp)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                'Speak at least ${TutorSessionController.minLearnerTurnsForXp} '
                'times in English to earn XP.',
                style: AppType.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          if (c.corrections.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Text('Sentences to remember', style: AppType.title),
            for (final s in c.corrections.toSet())
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s, style: AppType.body),
                trailing: c.savedCorrections.contains(s)
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.tealInk,
                      )
                    : TextButton(
                        onPressed: () => c.saveCorrection(s),
                        child: const Text('Save'),
                      ),
              ),
          ],
          const SizedBox(height: Space.md),
          AppButton(label: 'Done', onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ctx = widget.tutorContext;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: Text('The Professor', style: AppType.title),
        actions: [
          if (_c != null &&
              _c!.state != TutorState.ended &&
              _c!.state != TutorState.unavailable)
            TextButton(
              key: const ValueKey('speak_end'),
              onPressed: _end,
              child: const Text('End'),
            ),
        ],
      ),
      body: _c == null
          ? _Intro(context: ctx, onStart: _startSession)
          : ListenableBuilder(
              listenable: _c!,
              builder: (context, _) =>
                  _Session(c: _c!, text: _text, onRestart: _startSession),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: Space.xs),
        Expanded(child: Text(label, style: AppType.body)),
        Flexible(
          child: Text(value, style: AppType.label, textAlign: TextAlign.end),
        ),
      ],
    ),
  );
}

class _Intro extends StatelessWidget {
  const _Intro({required this.context, required this.onStart});
  final TutorContext? context;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext ctx) {
    final c = context;
    final lang = AppScope.of(ctx).native;
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        const Center(
          child: Mascot(
            character: CastMember.professor,
            mood: MascotMood.welcome,
            size: 110,
          ),
        ),
        const SizedBox(height: Space.md),
        Text(
          c?.hasLesson == true
              ? 'Roleplay "${c!.contentTitle}"'
              : 'Talk with the Professor',
          style: AppType.headline,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.xs),
        Text(
          'A live voice lesson. The Professor speaks English with you, '
          'explains in ${lang.englishName}, and asks you to repeat and use '
          'new expressions. Talk hands-free: the mic opens after each reply.',
          style: AppType.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        if (c != null && c.targetExpressions.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final e in c.targetExpressions)
                Chip(
                  label: Text(e, style: AppType.label),
                  backgroundColor: AppColors.goldTint,
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
        const SizedBox(height: Space.lg),
        AppButton(
          key: const ValueKey('speak_start'),
          label: 'Start conversation',
          icon: Icons.record_voice_over_rounded,
          onPressed: onStart,
        ),
        const SizedBox(height: Space.md),
        const _HowItWorks(),
        const SizedBox(height: Space.sm),
        Text(
          'Needs internet. English speech is recognised by your device; '
          'questions in ${lang.englishName} are transcribed by the tutor '
          'service. Nothing is stored.',
          style: AppType.caption.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.hearing_rounded, 'Listen', 'The Professor models a sentence'),
      (Icons.repeat_rounded, 'Repeat', 'Say it back; we check every word'),
      (Icons.chat_rounded, 'Use it', 'Answer in the roleplay'),
      (Icons.school_rounded, 'Learn', 'Get corrections in your language'),
    ];
    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: Column(
        children: [
          for (final (icon, title, sub) in steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.periwinkleInk),
                  const SizedBox(width: Space.sm),
                  Text('$title  ', style: AppType.label),
                  Expanded(
                    child: Text(
                      sub,
                      style: AppType.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Session extends StatelessWidget {
  const _Session({
    required this.c,
    required this.text,
    required this.onRestart,
  });
  final TutorSessionController c;
  final TextEditingController text;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    if (c.state == TutorState.unavailable) {
      return _Unavailable(c: c, onRetry: onRestart);
    }
    return Column(
      children: [
        _StateBanner(c: c),
        Expanded(
          child: ListView(
            key: const ValueKey('speak_transcript'),
            reverse: true,
            padding: const EdgeInsets.all(Space.gutter),
            children: [
              if (c.state == TutorState.listening && c.partial.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: 0.6,
                    child: SpeechBubble(
                      key: const ValueKey('speak_partial'),
                      text: c.partial,
                      color: AppColors.coralTint,
                      tail: BubbleTail.bottomRight,
                    ),
                  ),
                ),
              for (final t in c.turns.reversed) _TurnView(turn: t, c: c),
            ],
          ),
        ),
        if (c.state == TutorState.error)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: AppButton(
              key: const ValueKey('speak_retry'),
              label: 'Retry',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: c.retry,
            ),
          ),
        if (c.state == TutorState.ended)
          Padding(
            padding: const EdgeInsets.all(Space.gutter),
            child: AppButton(label: 'Start again', onPressed: onRestart),
          )
        else ...[
          if (c.currentTask != null) _TaskCard(c: c),
          _InputBar(c: c, text: text),
        ],
      ],
    );
  }
}

/// The Professor's stage: a large, expressive Professor whose state is
/// derived from real session events, a status line, and a REAL mic level
/// meter (shown only when the platform reports levels).
class _StateBanner extends StatelessWidget {
  const _StateBanner({required this.c});
  final TutorSessionController c;

  @override
  Widget build(BuildContext context) {
    final lang = c.native.englishName;
    final (label, color) = switch (c.state) {
      TutorState.connecting => ('Connecting…', AppColors.surfaceSunken),
      TutorState.listening => (
        'I\'m listening — speak English',
        AppColors.coralTint,
      ),
      TutorState.recordingNative => (
        'Ask me in $lang — I\'m listening',
        AppColors.goldTint,
      ),
      TutorState.transcribing => (
        'Understanding your question…',
        AppColors.goldTint,
      ),
      TutorState.thinking => ('Let me think…', AppColors.periwinkleTint),
      TutorState.speaking => (
        'Speaking — tap me to interrupt',
        AppColors.tealTint,
      ),
      TutorState.error => ('Something went wrong', AppColors.coralTint),
      TutorState.ended => ('Well done today!', AppColors.goldTint),
      _ => switch (c.professorState) {
        CharacterState.approving => (
          'Excellent! Your turn again.',
          AppColors.tealTint,
        ),
        CharacterState.correcting => (
          'Almost — let\'s fix one thing.',
          AppColors.goldTint,
        ),
        _ => ('Your turn', AppColors.surfaceSunken),
      },
    };
    final listeningNow =
        c.state == TutorState.listening ||
        c.state == TutorState.recordingNative;
    return Semantics(
      liveRegion: true,
      label: label,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.card),
        curve: Motion.emphasized,
        key: ValueKey('speak_state_${c.state.name}'),
        color: color,
        padding: const EdgeInsets.fromLTRB(
          Space.sm,
          Space.xs,
          Space.sm,
          Space.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ValueListenableBuilder<double?>(
              valueListenable: c.voiceLevel,
              builder: (context, amp, _) => CharacterAvatar(
                key: const ValueKey('speak_professor'),
                character: CastMember.professor,
                state: c.professorState,
                speaking: c.state == TutorState.speaking,
                voiceAmplitude: amp,
                size: 96,
                onTap: c.state == TutorState.speaking ? c.interrupt : null,
                semanticLabel: 'The Professor, ${c.professorState.name}',
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.feedback),
                    child: Text(
                      label,
                      key: ValueKey(label),
                      style: AppType.label,
                    ),
                  ),
                  if (c.message != null)
                    Text(c.message!, style: AppType.caption),
                  if (listeningNow)
                    ValueListenableBuilder<double?>(
                      valueListenable: c.level,
                      builder: (context, v, _) => v == null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.fiber_manual_record,
                                    color: AppColors.coralInk,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Mic on', style: AppType.caption),
                                ],
                              ),
                            )
                          : _LevelMeter(level: v),
                    ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _ToggleChip(
                        k: 'speak_live',
                        icon: c.liveMode
                            ? Icons.all_inclusive_rounded
                            : Icons.touch_app_rounded,
                        label: c.liveMode ? 'Live' : 'Manual',
                        on: c.liveMode,
                        onTap: c.micAvailable ? c.toggleLive : null,
                        tooltip: 'Live: the mic opens automatically after each reply',
                      ),
                      _ToggleChip(
                        k: 'speak_coach_voice',
                        icon: c.speakCoaching
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        label: c.native.code.toUpperCase(),
                        on: c.speakCoaching,
                        onTap: c.nativeVoiceAvailable
                            ? c.toggleCoachVoice
                            : null,
                        tooltip:
                            'Speak explanations in ${c.native.englishName}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Five bars driven by the real input level.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level});
  final double level;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Semantics(
      label: 'Microphone level ${(level * 100).round()} percent',
      excludeSemantics: true,
      child: Row(
        key: const ValueKey('speak_level_meter'),
        children: [
          for (var i = 0; i < 5; i++)
            AnimatedContainer(
              duration: Motion.of(context, Motion.press),
              margin: const EdgeInsets.only(right: 3),
              width: 6,
              height: 6 + 18 * (level - i * 0.15).clamp(0.0, 0.4) / 0.4,
              decoration: BoxDecoration(
                color: level > i * 0.18
                    ? AppColors.coral
                    : AppColors.outlineStrong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.k,
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
    required this.tooltip,
  });
  final String k;
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      key: ValueKey(k),
      borderRadius: BorderRadius.circular(Radii.pill),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: on && onTap != null ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: AppColors.outlineStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: onTap == null ? AppColors.disabledText : AppColors.indigo,
            ),
            const SizedBox(width: 2),
            Text(label, style: AppType.caption),
          ],
        ),
      ),
    ),
  );
}

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn, required this.c});
  final TutorTurn turn;
  final TutorSessionController c;

  @override
  Widget build(BuildContext context) {
    final tutor = turn.speaker == Speaker.tutor;
    final s = AppStrings.of(context);
    final f = turn.feedback;
    final score = turn.repeatScore;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Column(
        crossAxisAlignment: tutor
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          SpeechBubble(
            text: turn.text,
            color: tutor
                ? AppColors.periwinkleTint
                : (turn.language == 'en'
                      ? AppColors.coralTint
                      : AppColors.goldTint),
            tail: tutor ? BubbleTail.bottomLeft : BubbleTail.bottomRight,
          ),
          if (!tutor && turn.language != 'en')
            Padding(
              padding: const EdgeInsets.only(top: 2, right: Space.sm),
              child: Text(
                'Question in ${c.native.englishName}',
                style: AppType.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          if (tutor &&
              c.showTranslations &&
              turn.translation != null &&
              turn.translation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: Space.sm, top: 2),
              child: Directionality(
                textDirection: s.direction,
                child: Text(
                  '${turn.translation}  · ${s.en(S.aiTranslation)}',
                  style: AppType.caption.copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
          if (tutor && turn.coach != null)
            Container(
              key: const ValueKey('speak_coach'),
              margin: const EdgeInsets.only(top: Space.xs),
              padding: const EdgeInsets.fromLTRB(
                Space.sm,
                Space.xs,
                4,
                Space.xs,
              ),
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: Radii.mdAll,
                border: Border.all(color: AppColors.teal, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 6),
                    child: Icon(
                      Icons.school_rounded,
                      size: 18,
                      color: AppColors.tealInk,
                    ),
                  ),
                  Expanded(
                    child: Directionality(
                      textDirection: s.direction,
                      child: Text(turn.coach!, style: AppType.body),
                    ),
                  ),
                  if (c.nativeVoiceAvailable)
                    IconButton(
                      tooltip: 'Hear the explanation again',
                      visualDensity: VisualDensity.compact,
                      onPressed: c.canTalk ? () => c.replayCoach(turn) : null,
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
                    ),
                ],
              ),
            ),
          if (score != null)
            Container(
              key: const ValueKey('speak_repeat_score'),
              margin: const EdgeInsets.only(top: Space.xs),
              padding: const EdgeInsets.all(Space.xs),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: score.passed ? AppColors.tealTint : AppColors.coralTint,
                borderRadius: Radii.mdAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score.passed
                        ? 'Clear! ${(score.ratio * 100).round()}% of words recognised'
                        : '${(score.ratio * 100).round()}% recognised — try the missing words',
                    style: AppType.label,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final w in score.words)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: w.heard
                                ? AppColors.surface
                                : AppColors.coral,
                            borderRadius: Radii.smAll,
                          ),
                          child: Text(w.word, style: AppType.caption),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (f != null)
            Container(
              key: const ValueKey('speak_feedback'),
              margin: const EdgeInsets.only(top: Space.xs),
              padding: const EdgeInsets.all(Space.sm),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: f.kind == FeedbackKind.great
                    ? AppColors.tealTint
                    : AppColors.goldTint,
                borderRadius: Radii.mdAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.kind == FeedbackKind.great ? 'Nice!' : 'Tip',
                    style: AppType.label,
                  ),
                  Text(f.note, style: AppType.bodySmall),
                  if (f.suggestion != null) ...[
                    Text(
                      'Try: "${f.suggestion}"',
                      style: AppType.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: c.savedCorrections.contains(f.suggestion)
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.bookmark_added_rounded,
                                color: AppColors.tealInk,
                              ),
                            )
                          : TextButton.icon(
                              key: const ValueKey('speak_save_correction'),
                              onPressed: () => c.saveCorrection(f.suggestion!),
                              icon: const Icon(
                                Icons.bookmark_add_rounded,
                                size: 18,
                              ),
                              label: const Text('Save to My Words'),
                            ),
                    ),
                  ],
                  if (f.noteNative != null && f.noteNative!.isNotEmpty)
                    Directionality(
                      textDirection: s.direction,
                      child: Text(
                        '${f.noteNative}  · ${s.en(S.aiTranslation)}',
                        style: AppType.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pinned "your turn" card: exactly what to say next, in English and the
/// learner's language, with listen + hint.
class _TaskCard extends StatefulWidget {
  const _TaskCard({required this.c});
  final TutorSessionController c;

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _hint = false;
  TutorTask? _forTask;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final task = c.currentTask!;
    if (!identical(task, _forTask)) {
      _forTask = task;
      _hint = false;
    }
    final hint = c.lastTutorTurn?.hint;
    final s = AppStrings.of(context);
    final title = switch (task.type) {
      TaskType.repeat => 'Repeat after me',
      TaskType.answer => 'Answer in English',
      TaskType.useExpression => 'Use the expression',
    };
    return Container(
      key: const ValueKey('speak_task'),
      margin: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.xs,
      ),
      padding: const EdgeInsets.fromLTRB(Space.sm, Space.xs, 4, Space.xs),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: Radii.lgAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppType.overline.copyWith(color: AppColors.goldInk),
                ),
                Text(task.prompt, style: AppType.titleSmall),
                if (task.promptNative != null)
                  Directionality(
                    textDirection: s.direction,
                    child: Text(
                      task.promptNative!,
                      style: AppType.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                if (_hint && hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'e.g. "$hint"',
                      key: const ValueKey('speak_hint_text'),
                      style: AppType.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (c.englishVoice)
            IconButton(
              tooltip: 'Hear it in English',
              onPressed: c.canTalk
                  ? () => c.sayEnglish(
                      task.type == TaskType.repeat
                          ? task.prompt
                          : (hint ?? task.prompt),
                    )
                  : null,
              icon: const Icon(Icons.volume_up_rounded),
            ),
          if (hint != null && task.type != TaskType.repeat)
            IconButton(
              key: const ValueKey('speak_hint'),
              tooltip: 'Show a sample answer',
              onPressed: () => setState(() => _hint = !_hint),
              icon: Icon(
                _hint
                    ? Icons.lightbulb_rounded
                    : Icons.lightbulb_outline_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.c, required this.text});
  final TutorSessionController c;
  final TextEditingController text;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final listening = c.state == TutorState.listening;
    final recordingNative = c.state == TutorState.recordingNative;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          4,
          Space.gutter,
          Space.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (c.nativeVoiceAvailable)
                  _RoundButton(
                    k: 'speak_ask_native',
                    size: 56,
                    icon: recordingNative
                        ? Icons.stop_rounded
                        : Icons.help_outline_rounded,
                    color: AppColors.gold,
                    border: AppColors.goldShade,
                    enabled: c.canTalk || recordingNative,
                    label: 'Ask in ${c.native.endonym}',
                    onTap: recordingNative
                        ? c.stopNativeQuestion
                        : c.startNativeQuestion,
                  ),
                if (c.nativeVoiceAvailable) const SizedBox(width: Space.lg),
                if (c.micAvailable)
                  _RoundButton(
                    k: 'speak_talk',
                    size: listening ? 92 : 80,
                    icon: listening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: AppColors.coral,
                    border: AppColors.coralShade,
                    enabled: c.canTalk || listening,
                    label: listening ? 'Tap to send' : 'Speak English',
                    onTap: listening ? c.stopListening : c.startListening,
                  ),
              ],
            ),
            if (c.micAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  listening
                      ? 'Tap when you finish speaking'
                      : s.en(S.holdToTalk).replaceFirst('Hold', 'Tap'),
                  style: AppType.caption.copyWith(color: AppColors.textMuted),
                ),
              ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('speak_text'),
                    controller: text,
                    enabled: c.canTalk,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText:
                          'Or type (English, or a question in ${c.native.endonym})',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (v) {
                      c.sendText(v, language: _guessLanguage(v, c));
                      text.clear();
                    },
                  ),
                ),
                IconButton(
                  key: const ValueKey('speak_send'),
                  tooltip: 'Send',
                  onPressed: c.canTalk
                      ? () {
                          c.sendText(
                            text.text,
                            language: _guessLanguage(text.text, c),
                          );
                          text.clear();
                        }
                      : null,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ethiopic script means an Amharic question; Oromo (Latin) typed text is
  /// treated as English practice unless it is clearly not English.
  static String _guessLanguage(String v, TutorSessionController c) =>
      v.runes.any((r) => r >= 0x1200 && r <= 0x137F) ? c.native.code : 'en';
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.k,
    required this.size,
    required this.icon,
    required this.color,
    required this.border,
    required this.enabled,
    required this.label,
    required this.onTap,
  });
  final String k;
  final double size;
  final IconData icon;
  final Color color;
  final Color border;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          key: ValueKey(k),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? color : AppColors.disabledFill,
              border: Border.all(
                color: enabled ? border : AppColors.outline,
                width: 4,
              ),
            ),
            child: Icon(icon, size: size * 0.45, color: AppColors.indigo),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: AppType.caption),
    ],
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.c, required this.onRetry});
  final TutorSessionController c;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final targets = c.context.targetExpressions;
    return ListView(
      key: const ValueKey('speak_unavailable'),
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        const Center(
          child: Mascot(
            character: CastMember.professor,
            mood: MascotMood.sleeping,
            size: 130,
          ),
        ),
        const SizedBox(height: Space.sm),
        LabelWithSupport(
          S.professorOffline,
          style: AppType.title,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        const SizedBox(height: Space.xs),
        Text(
          c.message ?? 'The live tutor needs an internet connection.',
          style: AppType.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.lg),
        AppButton(
          key: const ValueKey('speak_try_again'),
          label: 'Try again',
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
        ),
        const SizedBox(height: Space.lg),
        Text('Offline practice (not AI)', style: AppType.overline),
        const SizedBox(height: Space.xs),
        Text(
          targets.isEmpty
              ? 'Review your saved words while you are offline.'
              : 'Say these out loud, then review them in My Words:',
          style: AppType.body,
        ),
        for (final e in targets)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text('• $e', style: AppType.titleSmall),
          ),
        const SizedBox(height: Space.md),
        AppButton(
          key: const ValueKey('speak_offline_review'),
          label: 'Review My Words',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.revision),
        ),
      ],
    );
  }
}
