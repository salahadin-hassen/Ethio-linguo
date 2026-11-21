// Contact sheet of the interim code-rigged characters: expressions and
// mid-gesture frames, rendered by the real painters/motor.
@Tags(['screenshots'])
library;

import 'package:ethio_linguo/core/theme/app_colors.dart';
import 'package:ethio_linguo/features/mascot/mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('puppet sheet', (t) async {
    t.view.physicalSize = const Size(1500, 760);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final cells =
        <
          (
            String,
            CastMember,
            CharacterRigController,
            void Function(CharacterRigController),
          )
        >[
          ('Spark rest', CastMember.spark, CharacterRigController(), (_) {}),
          (
            'Spark happy',
            CastMember.spark,
            CharacterRigController(),
            (r) => r.setEmotion(RigEmotion.happy),
          ),
          (
            'Spark surprised',
            CastMember.spark,
            CharacterRigController(),
            (r) => r.setEmotion(RigEmotion.surprised),
          ),
          (
            'Spark thinking',
            CastMember.spark,
            CharacterRigController(),
            (r) => r
              ..setThinking(true)
              ..setEmotion(RigEmotion.thinking),
          ),
          (
            'Spark wave',
            CastMember.spark,
            CharacterRigController(),
            (r) => r.wave(),
          ),
          (
            'Spark celebrate',
            CastMember.spark,
            CharacterRigController(),
            (r) => r.celebrate(),
          ),
          ('Prof rest', CastMember.professor, CharacterRigController(), (_) {}),
          (
            'Prof listening',
            CastMember.professor,
            CharacterRigController(),
            (r) => r.applyState(CharacterState.listening),
          ),
          (
            'Prof thinking',
            CastMember.professor,
            CharacterRigController(),
            (r) => r.applyState(
              CharacterState.thinking,
              previous: CharacterState.idle,
            ),
          ),
          (
            'Prof speaking',
            CastMember.professor,
            CharacterRigController(),
            (r) => r.setSpeaking(true),
          ),
          (
            'Prof explain',
            CastMember.professor,
            CharacterRigController(),
            (r) => r.explain(),
          ),
          (
            'Prof approve',
            CastMember.professor,
            CharacterRigController(),
            (r) => r.correctAnswer(),
          ),
        ];
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.ivory,
          body: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (label, who, rig, _) in cells)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: Colors.white,
                      child: CharacterAvatar(
                        character: who,
                        state: CharacterState.idle,
                        rig: rig,
                        size: 230,
                      ),
                    ),
                    Text(label, style: const TextStyle(fontFamily: 'Nunito')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    for (final (_, _, rig, act) in cells) {
      act(rig);
    }
    // Let springs/gestures reach expressive mid-action frames.
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 20));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/puppet_sheet.png'),
    );
  });
}
