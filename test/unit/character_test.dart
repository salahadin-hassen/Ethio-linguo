import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/data/models/progress.dart';
import 'package:ethio_linguo/features/companion/companion_lines.dart';
import 'package:ethio_linguo/features/mascot/mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cast poses', () {
    test('every state maps to real artwork for every cast member', () {
      for (final m in CastMember.values) {
        for (final s in CharacterState.values) {
          expect(availablePoses[m], contains(poseForState(m, s)));
        }
      }
    });

    test('one companion identity: Spark for every non-celebration mood', () {
      for (final mood in MascotMood.values) {
        final (who, _) = castForMood(mood);
        final expected = switch (mood) {
          MascotMood.celebrating => CastMember.beat,
          MascotMood.sleeping => CastMember.wry,
          _ => CastMember.spark,
        };
        expect(who, expected, reason: mood.name);
      }
    });

    test('Professor states pick teaching/thinking/approval poses', () {
      const p = CastMember.professor;
      expect(poseForState(p, CharacterState.thinking), CharacterPose.thinking);
      expect(poseForState(p, CharacterState.speaking), CharacterPose.teaching);
      expect(poseForState(p, CharacterState.approving), CharacterPose.correct);
      expect(
        poseForState(p, CharacterState.listening),
        isNot(CharacterPose.thinking),
      );
    });
  });

  group('Spark lines follow real progress', () {
    Line g(
      LearnerProgress p, {
      int xp = 0,
      int thirsty = 0,
      bool quests = false,
    }) => SparkLines.greeting(
      p: p,
      today: '2026-11-21',
      hour: 9,
      thirstyWords: thirsty,
      questsDone: quests,
      xpGainedSinceLastVisit: xp,
    );

    test('first visit waves hello', () {
      final l = g(const LearnerProgress(onboarded: true));
      expect(l.state, CharacterState.waving);
      expect(l.native(NativeLanguage.amharic), isNotNull);
    });
    test('XP just earned -> excited with the real amount', () {
      final l = g(const LearnerProgress(onboarded: true), xp: 15);
      expect(l.en, contains('+15 XP'));
      expect(l.state, CharacterState.excited);
    });
    test('returning after a break -> welcome back, no guilt', () {
      final l = g(
        const LearnerProgress(
          onboarded: true,
          completedNodeIds: {'n1'},
          lastActiveDay: '2026-11-15',
          streak: 4,
        ),
      );
      expect(l.en, startsWith('Welcome back'));
      expect(l.en.toLowerCase(), isNot(contains('lost')));
    });
    test('thirsty words are mentioned when relevant', () {
      final l = g(
        const LearnerProgress(
          onboarded: true,
          completedNodeIds: {'n1'},
          lastActiveDay: '2026-11-20',
        ),
        thirsty: 2,
      );
      expect(l.en, contains('2 words need water'));
    });
  });

  testWidgets('reduced motion: character renders with no running animation', (
    t,
  ) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: CharacterAvatar(
          character: CastMember.spark,
          state: CharacterState.idle,
          onTap: () => taps++,
        ),
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        home: CharacterAvatar(
          character: CastMember.spark,
          state: CharacterState.celebrating,
          onTap: () => taps++,
        ),
      ),
    );
    expect(t.binding.hasScheduledFrame, isFalse);
    await t.tap(find.byType(CharacterAvatar));
    expect(taps, 1);
  });

  group('rig controller (app -> Rive contract)', () {
    test('real events map to rig inputs and one trigger per transition', () {
      final rig = CharacterRigController();
      rig.applyState(CharacterState.listening, previous: CharacterState.idle);
      expect(rig.listening, isTrue);
      expect(rig.drainTriggers(), [RigContract.nod]);
      rig.applyState(
        CharacterState.thinking,
        previous: CharacterState.listening,
      );
      expect((rig.listening, rig.thinking), (false, true));
      expect(rig.emotion, RigEmotion.thinking);
      rig.applyState(
        CharacterState.approving,
        previous: CharacterState.thinking,
      );
      expect(rig.drainTriggers(), [RigContract.correctAnswer]);
      rig.applyState(
        CharacterState.approving,
        previous: CharacterState.approving,
      );
      expect(
        rig.drainTriggers(),
        isEmpty,
        reason: 'no re-trigger without change',
      );
      rig.applyState(CharacterState.correcting, previous: CharacterState.idle);
      expect(rig.drainTriggers(), [RigContract.incorrectAnswer]);
      expect(rig.emotion, RigEmotion.encouraging);
    });

    test('speaking mirrors real playback; amplitude only when provided', () {
      final rig = CharacterRigController()..setSpeaking(true);
      expect(rig.speaking, isTrue);
      expect(rig.voiceAmplitude, isNull, reason: 'never synthesised');
      rig.setSpeaking(false, amplitude: 0.8);
      expect(rig.voiceAmplitude, isNull);
    });

    test('tap looks toward the touch, then reacts; variants rotate', () {
      final rig = CharacterRigController()..reactToTap(x: 0.6, y: -2);
      expect((rig.gazeX, rig.gazeY), (0.6, -1.0));
      expect(rig.drainTriggers(), [RigContract.tapReaction]);
      rig.setIdleVariant(4);
      expect(rig.idleVariant, 1);
    });

    test('contract: every cast rig names its artboard and state machine', () {
      expect(RigContract.specs.keys, {CastMember.spark, CastMember.professor});
      for (final s in RigContract.specs.values) {
        expect(s.asset, endsWith('.riv'));
        expect(s.stateMachine, endsWith('Character'));
      }
    });
  });

  testWidgets('no rig bundled -> honest static pose, no transform motion', (
    t,
  ) async {
    final rig = CharacterRigController();
    Widget at(CharacterState s) => MaterialApp(
      home: CharacterAvatar(
        character: CastMember.professor,
        state: s,
        rig: rig,
        onTap: () {},
      ),
    );
    await t.pumpWidget(at(CharacterState.correcting));
    await t.pumpAndSettle();
    await t.pumpWidget(at(CharacterState.approving));
    await t.pumpAndSettle();
    expect(find.byType(Transform), findsNothing);
    expect(find.bySemanticsLabel('The Professor, approving'), findsOneWidget);
    expect(rig.drainTriggers(), contains(RigContract.correctAnswer));
    await t.tap(find.byType(CharacterAvatar));
    expect(rig.drainTriggers(), [RigContract.tapReaction]);
  });
}
