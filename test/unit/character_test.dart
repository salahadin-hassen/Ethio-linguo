import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/data/models/progress.dart';
import 'package:ethio_linguo/features/companion/companion_lines.dart';
import 'package:ethio_linguo/features/mascot/mascot.dart';
import 'package:ethio_linguo/features/mascot/puppet/puppet_character.dart';
import 'package:ethio_linguo/features/mascot/rig/rive_character.dart';
import 'package:ethio_linguo/features/mascot/puppet/puppet_motor.dart';
import 'package:ethio_linguo/features/mascot/puppet/puppet_specs.dart';
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

  testWidgets(
    'no rig bundled -> code-rigged puppet, no whole-image transform',
    (t) async {
      RigAssets.debugOverride(const {});
      addTearDown(RigAssets.reset);
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
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
      await t.pumpAndSettle(); // reduced motion: event-driven, settles
      expect(find.byType(PuppetCharacter), findsOneWidget);
      expect(find.byType(Transform), findsNothing);
      expect(find.bySemanticsLabel('The Professor, approving'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await t.tap(find.byType(CharacterAvatar));
        await t.pump(const Duration(milliseconds: 400));
      }
      expect(rig.idleVariant, 1, reason: 'repeated taps vary the reaction');
    },
  );

  group('puppet motor (part-based motion)', () {
    PuppetMotor motor(CharacterRigController r) =>
        PuppetMotor(ProfessorSpec(), r, seed: 7);
    void run(PuppetMotor m, double seconds) {
      for (var i = 0; i < seconds * 60; i++) {
        m.tick(1 / 60);
      }
    }

    test('idle is alive: breathing + irregular blinks, mouth closed', () {
      final m = motor(CharacterRigController());
      final breaths = <double>{};
      var blinks = 0;
      var wasClosed = false;
      for (var i = 0; i < 30 * 60; i++) {
        m.tick(1 / 60);
        breaths.add((m.pose.breath * 10).roundToDouble());
        final closed = m.pose.lidL > 0.8;
        if (closed && !wasClosed) blinks++;
        wasClosed = closed;
        expect(m.pose[Ch.mouthOpen], lessThan(0.2));
      }
      expect(breaths.length, greaterThan(5));
      expect(
        blinks,
        inInclusiveRange(4, 18),
        reason: '30 s of natural blinking',
      );
    });

    test('mouth moves only while real audio plays', () {
      final r = CharacterRigController();
      final m = motor(r);
      run(m, 1);
      r.setSpeaking(true);
      var maxOpen = 0.0;
      for (var i = 0; i < 120; i++) {
        m.tick(1 / 60);
        maxOpen = maxOpen > m.pose[Ch.mouthOpen]
            ? maxOpen
            : m.pose[Ch.mouthOpen];
      }
      expect(maxOpen, greaterThan(0.3));
      r.setSpeaking(false);
      run(m, 1);
      expect(m.pose[Ch.mouthOpen], lessThan(0.1));
    });

    test('gesture: anticipation -> action -> recovery to rest', () {
      final r = CharacterRigController();
      final m = motor(r);
      run(m, 0.5);
      final rest = m.pose[Ch.armRUp];
      r.explain();
      run(m, 0.8);
      expect(m.pose[Ch.armRUp], greaterThan(rest + 0.6), reason: 'hand raised');
      expect(m.pose.handR, Hand.open);
      run(m, 2.5);
      expect((m.pose[Ch.armRUp] - rest).abs(), lessThan(0.1));
    });

    test('thinking: hand to chin and eyes up-away', () {
      final r = CharacterRigController()
        ..applyState(CharacterState.thinking, previous: CharacterState.idle);
      final m = motor(r);
      run(m, 1.5);
      expect(m.pose.handR, Hand.chin);
      expect(m.pose[Ch.pupilY], lessThan(-0.4));
    });
  });
}
