import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../core/components/app_button.dart';
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

/// The Professor. Works as a tab (free conversation) or as a route with a
/// lesson [TutorContext].
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
            TutorContext(native: app.native, level: app.profile.level),
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
    final reward = await _c!.end();
    if (!mounted) return;
    if (reward != null) {
      await showActivityReward(
        context,
        reward,
        title: 'Great conversation!',
        detail: _c!.usedExpressions.isEmpty
            ? 'You spoke ${_c!.learnerTurns} times.'
            : 'You used: ${_c!.usedExpressions.join(', ')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.tutorContext;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: Text('The Professor', style: AppType.title),
        actions: [
          if (_c != null && _c!.state != TutorState.ended)
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

class _Intro extends StatelessWidget {
  const _Intro({required this.context, required this.onStart});
  final TutorContext? context;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext ctx) {
    final c = context;
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        const Center(child: Mascot(mood: MascotMood.welcome, size: 150)),
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
          c?.hasLesson == true
              ? 'The Professor plays the other person in the scene you watched. '
                    'Try to use your new expressions.'
              : 'Practise everyday English out loud. Open a Discover video first '
                    'to practise a specific scene.',
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
        const SizedBox(height: Space.sm),
        Text(
          'Needs an internet connection. Speech is recognised on your phone; '
          'only the text is sent to the tutor service, and nothing is stored.',
          style: AppType.caption.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
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
                      text: c.partial,
                      color: AppColors.coralTint,
                      tail: BubbleTail.bottomRight,
                    ),
                  ),
                ),
              for (final t in c.turns.reversed) _TurnView(turn: t),
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
        else
          _InputBar(c: c, text: text),
      ],
    );
  }
}

class _StateBanner extends StatelessWidget {
  const _StateBanner({required this.c});
  final TutorSessionController c;

  @override
  Widget build(BuildContext context) {
    final (label, mood, color) = switch (c.state) {
      TutorState.connecting => (
        'Connecting…',
        MascotMood.thinking,
        AppColors.surfaceSunken,
      ),
      TutorState.listening => (
        'Listening…',
        MascotMood.excited,
        AppColors.coralTint,
      ),
      TutorState.thinking => (
        'The Professor is thinking…',
        MascotMood.thinking,
        AppColors.periwinkleTint,
      ),
      TutorState.speaking => (
        'Speaking…',
        MascotMood.happy,
        AppColors.tealTint,
      ),
      TutorState.error => (
        'Something went wrong',
        MascotMood.confused,
        AppColors.coralTint,
      ),
      TutorState.ended => (
        'Conversation ended',
        MascotMood.celebrating,
        AppColors.goldTint,
      ),
      _ => ('Your turn', MascotMood.encouraging, AppColors.surfaceSunken),
    };
    return Semantics(
      liveRegion: true,
      label: label,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.medium),
        key: ValueKey('speak_state_${c.state.name}'),
        color: color,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: Space.xs,
        ),
        child: Row(
          children: [
            Mascot(mood: mood, size: 48, semanticLabel: 'Professor'),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppType.label),
                  if (c.message != null)
                    Text(c.message!, style: AppType.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn});
  final TutorTurn turn;

  @override
  Widget build(BuildContext context) {
    final tutor = turn.speaker == Speaker.tutor;
    final s = AppStrings.of(context);
    final f = turn.feedback;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Column(
        crossAxisAlignment: tutor
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          SpeechBubble(
            text: turn.text,
            color: tutor ? AppColors.periwinkleTint : AppColors.coralTint,
            tail: tutor ? BubbleTail.bottomLeft : BubbleTail.bottomRight,
          ),
          if (tutor && turn.translation != null)
            Padding(
              padding: const EdgeInsets.only(left: Space.sm, top: 2),
              child: Text(
                '${turn.translation}  · ${s.en(S.aiTranslation)}',
                style: AppType.caption.copyWith(color: AppColors.textMuted),
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
                  if (f.suggestion != null)
                    Text(
                      'Try: "${f.suggestion}"',
                      style: AppType.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (f.noteNative != null)
                    Text(
                      '${f.noteNative}  · ${s.en(S.aiTranslation)}',
                      style: AppType.caption.copyWith(
                        color: AppColors.textMuted,
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

class _InputBar extends StatelessWidget {
  const _InputBar({required this.c, required this.text});
  final TutorSessionController c;
  final TextEditingController text;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.xs,
          Space.gutter,
          Space.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.micAvailable)
              GestureDetector(
                key: const ValueKey('speak_talk'),
                onLongPressStart: (_) => c.startListening(),
                onLongPressEnd: (_) => c.stopListening(),
                child: Semantics(
                  button: true,
                  label: s.en(S.holdToTalk),
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.fast),
                    width: c.state == TutorState.listening ? 104 : 88,
                    height: c.state == TutorState.listening ? 104 : 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.canTalk || c.state == TutorState.listening
                          ? AppColors.coral
                          : AppColors.disabledFill,
                      border: Border.all(color: AppColors.coralShade, width: 4),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      size: 40,
                      color: AppColors.indigo,
                    ),
                  ),
                ),
              ),
            if (c.micAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: Space.xs),
                child: LabelWithSupport(
                  S.holdToTalk,
                  style: AppType.caption,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('speak_text'),
                    controller: text,
                    enabled: c.canTalk,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Or type in English…',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (v) {
                      c.sendText(v);
                      text.clear();
                    },
                  ),
                ),
                IconButton(
                  key: const ValueKey('speak_send'),
                  tooltip: 'Send',
                  onPressed: c.canTalk
                      ? () {
                          c.sendText(text.text);
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
        const Center(child: Mascot(mood: MascotMood.sleeping, size: 130)),
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
