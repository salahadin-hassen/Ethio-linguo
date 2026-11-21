@Tags(['screenshots'])
library;

import 'package:ethio_linguo/core/theme/app_colors.dart';
import 'package:ethio_linguo/features/mascot/mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('mascot expression sheet', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.ivory,
          body: Center(
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                for (final m in MascotMood.values)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Mascot(mood: m, size: 300, animate: false),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.name,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in [24.0, 40.0, 64.0])
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Mascot(
                          mood: MascotMood.happy,
                          size: s,
                          animate: false,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('out/mascot_sheet.png'),
    );
  });
}
