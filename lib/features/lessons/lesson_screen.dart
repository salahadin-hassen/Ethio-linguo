import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_services.dart';
import '../../services/audio/sound_effects.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_sheet.dart';
import '../../core/components/empty_state.dart';
import '../../core/components/speech_bubble.dart';
import '../../core/motion/motion.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/course.dart';
import '../../data/models/exercise.dart';
import '../mascot/mascot.dart';
import 'exercises/build_sentence_view.dart';
import 'exercises/match_pairs_view.dart';
import 'exercises/multiple_choice_view.dart';
import 'exercises/type_answer_view.dart';
import 'lesson_launch.dart';
import 'logic/answer_validator.dart';
import 'logic/lesson_builder.dart';
import 'logic/lesson_session.dart';
import 'widgets/feedback_panel.dart';
import 'widgets/lesson_top_bar.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.launch});

  final LessonLaunch launch;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  LessonSession? _session;
  NodeKind? _kindOverride;
  bool _finishing = false;
  bool _heartLostThisTurn = false;

  // Pending answers for the current exercise.
  int? _choice;
  final _typed = TextEditingController();
  List<int> _placed = const [];
  int _attempt = 0; // bumps to reset per-exercise widget state

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    final builder = LessonBuilder(app.course, app.native);
    final (String nodeId, List<Exercise> exercises) = switch (widget.launch) {
      NodeLaunch(:final nodeId) => (
        nodeId,
        _buildForNode(app, builder, nodeId),
      ),
      GardenReviewLaunch(:final termIds) => (
        GardenReviewLaunch.nodeId,
        builder.buildReview(termIds, id: GardenReviewLaunch.nodeId),
      ),
    };
    if (widget.launch is GardenReviewLaunch) _kindOverride = NodeKind.practice;
    if (exercises.isNotEmpty) {
      _session = LessonSession(
        nodeId: nodeId,
        exercises: exercises,
        hearts: app.progress.hearts,
        onHeartLost: (h) => app.setHearts(h),
      )..addListener(_onSession);
    }
    _typed.addListener(() => setState(() {}));
  }

  static List<Exercise> _buildForNode(
    AppController app,
    LessonBuilder b,
    String nodeId,
  ) {
    final node = app.course.nodeById(nodeId);
    if (node == null) return const [];
    final lesson = node.lessonId == null
        ? null
        : app.course.lessons[node.lessonId];
    if (lesson != null) return b.buildLesson(lesson);
    return b.buildReview(
      node.reviewTermIds,
      id: node.id,
      checkpoint: node.kind == NodeKind.checkpoint,
    );
  }

  @override
  void dispose() {
    _session?.removeListener(_onSession);
    _session?.dispose();
    _typed.dispose();
    super.dispose();
  }

  void _onSession() {
    if (_session!.phase == SessionPhase.finished) {
      _finish();
    } else {
      setState(() {});
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final app = AppScope.read(context);
    final reward = await app.completeLesson(
      _session!.result(),
      kindOverride: _kindOverride,
    );
    if (!mounted) return;
    // Bigger events get the bigger sound; never both.
    ServicesScope.of(context).sounds.play(
      reward.newAchievements.isNotEmpty || reward.leveledUp
          ? Sfx.achievement
          : Sfx.complete,
    );
    Navigator.of(context)
        .pushReplacementNamed(AppRoutes.complete, arguments: reward);
  }

  bool get _canCheck {
    final s = _session!;
    if (s.phase != SessionPhase.answering) return false;
    return switch (s.current) {
      MultipleChoiceExercise() => _choice != null,
      TypeAnswerExercise() => _typed.text.trim().isNotEmpty,
      BuildSentenceExercise() => _placed.isNotEmpty,
      MatchPairsExercise() => false,
    };
  }

  void _check() {
    if (!_canCheck) return;
    final s = _session!;
    final verdict = switch (s.current) {
      final MultipleChoiceExercise e => AnswerValidator.checkChoice(e, _choice),
      final TypeAnswerExercise e => AnswerValidator.checkTyped(e, _typed.text),
      final BuildSentenceExercise e => AnswerValidator.checkSentence(e, [
        for (final i in _placed) e.tiles[i],
      ]),
      MatchPairsExercise() => Verdict.correct,
    };
    _submit(verdict);
  }

  void _submit(Verdict v) {
    final s = _session!;
    final before = s.hearts;
    FocusScope.of(context).unfocus();
    final sounds = ServicesScope.of(context).sounds;
    if (v == Verdict.incorrect) {
      HapticFeedback.mediumImpact();
      sounds.play(Sfx.incorrect);
    } else {
      HapticFeedback.lightImpact();
      sounds.play(Sfx.correct);
    }
    s.submit(v);
    _heartLostThisTurn = s.hearts < before;
  }

  void _next() {
    setState(() {
      _choice = null;
      _placed = const [];
      _typed.clear();
      _attempt++;
    });
    _session!.next();
  }

  Future<void> _confirmQuit() async {
    final quit = await showAppSheet<bool>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(mood: MascotMood.encouraging, size: 110),
          const SizedBox(height: Space.sm),
          Text('Leave this lesson?', style: AppType.title),
          const SizedBox(height: 4),
          Text(
            "You're doing great. If you leave now, this lesson's progress won't be saved.",
            textAlign: TextAlign.center,
            style: AppType.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: Space.lg),
          AppButton(
            label: 'Keep learning',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          const SizedBox(height: Space.xs),
          AppButton(
            key: const ValueKey('confirm_quit'),
            label: 'Quit lesson',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (quit == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(
            mood: MascotMood.confused,
            title: 'Nothing to practise yet',
            message: 'This session has no content available offline. Try another lesson from your path.',
            actionLabel: 'Back',
            onAction: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
    if (s.phase == SessionPhase.finished) {
      // Reward is being saved; completion screen replaces this route.
      return const Scaffold(
        body: Center(child: Mascot(mood: MascotMood.celebrating, size: 160)),
      );
    }
    final ex = s.current;
    final verdict = s.lastVerdict;
    final inFeedback = s.phase == SessionPhase.feedback && verdict != null;
    final native = AppScope.read(context).native;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              LessonTopBar(
                progress: s.progress,
                hearts: s.hearts,
                practiceMode: s.practiceMode,
                onClose: _confirmQuit,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.medium),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Motion.emphasized,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey('ex_$_attempt'),
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      Space.sm,
                      Space.gutter,
                      Space.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.isRetry)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.xs),
                            child: Text(
                              'PREVIOUS MISTAKE',
                              style: AppType.overline.copyWith(
                                color: AppColors.coralInk,
                              ),
                            ),
                          ),
                        Semantics(
                          header: true,
                          child: Text(ex.instruction, style: AppType.headline),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ex.nativeInstruction,
                          style: AppType.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: Space.lg),
                        if (ex is! MatchPairsExercise) ...[
                          _PromptRow(
                            prompt: switch (ex) {
                              MultipleChoiceExercise(:final prompt) => prompt,
                              TypeAnswerExercise(:final prompt) => prompt,
                              BuildSentenceExercise(:final prompt) => prompt,
                              MatchPairsExercise() => '',
                            },
                            state: verdict == null
                                ? CharacterState.curious
                                : verdict == Verdict.incorrect
                                ? CharacterState.confused
                                : CharacterState.happy,
                          ),
                          const SizedBox(height: Space.lg),
                        ],
                        _exerciseBody(ex, verdict),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.medium),
                transitionBuilder: (child, anim) => SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: anim,
                    curve: Motion.emphasized,
                  ),
                  alignment: Alignment.topCenter,
                  child: child,
                ),
                child: inFeedback
                    ? FeedbackPanel(
                        key: ValueKey('fb_$_attempt'),
                        verdict: verdict,
                        solution: ex.solutionText,
                        native: native,
                        onContinue: _next,
                        run: s.streakRun,
                        heartLost: _heartLostThisTurn,
                        practiceMode: s.practiceMode,
                        willRetry: verdict == Verdict.incorrect && !s.isRetry,
                      )
                    : ex is MatchPairsExercise
                    ? const SizedBox(key: ValueKey('none'), height: 0)
                    : Container(
                        key: const ValueKey('check'),
                        padding: const EdgeInsets.fromLTRB(
                          Space.gutter,
                          Space.sm,
                          Space.gutter,
                          Space.md,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.outline,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: AppButton(
                            key: const ValueKey('check_button'),
                            label: 'Check',
                            onPressed: _canCheck ? _check : null,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseBody(Exercise ex, Verdict? verdict) => switch (ex) {
    final MultipleChoiceExercise e => MultipleChoiceView(
      exercise: e,
      selected: _choice,
      verdict: verdict,
      onSelect: (i) => setState(() => _choice = i),
    ),
    TypeAnswerExercise() => TypeAnswerView(
      controller: _typed,
      verdict: verdict,
      onSubmitted: _check,
    ),
    final BuildSentenceExercise e => BuildSentenceView(
      exercise: e,
      placed: _placed,
      verdict: verdict,
      onAdd: (i) => setState(() {
        if (!_placed.contains(i)) _placed = [..._placed, i];
      }),
      onRemoveAt: (pos) => setState(() {
        if (pos < _placed.length) _placed = [..._placed]..removeAt(pos);
      }),
    ),
    final MatchPairsExercise e => MatchPairsView(
      key: ValueKey('match_$_attempt'),
      exercise: e,
      locked: verdict != null,
      onCompleted: (_) => _submit(Verdict.correct),
    ),
  };
}

/// Mascot "speaking" the prompt in a bubble.
class _PromptRow extends StatelessWidget {
  const _PromptRow({required this.prompt, required this.state});

  final String prompt;

  /// Driven by the real verdict: curious (waiting) -> happy / confused.
  final CharacterState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CharacterAvatar(character: CastMember.spark, state: state, size: 100),
        const SizedBox(width: Space.xs),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: SpeechBubble(
              key: const ValueKey('prompt_bubble'),
              text: prompt,
              tail: BubbleTail.left,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              style: AppType.prompt,
            ),
          ),
        ),
      ],
    );
  }
}
