import 'dart:io';

import 'package:ethio_linguo/core/theme/app_typography.dart';
import 'package:ethio_linguo/data/local/demo_course.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/cmap.dart';
import '../helpers/fonts.dart';

bool isEthiopic(int c) =>
    (c >= 0x1200 && c <= 0x139F) ||
    (c >= 0x2D80 && c <= 0x2DDF) ||
    (c >= 0xAB00 && c <= 0xAB2F);

/// Every non-ASCII character that appears in app source AND bundled content
/// (subtitles, translations). Comments are included, which is stricter.
Set<int> nonAsciiCharsInLib() => {
  for (final (dir, ext) in [('lib', '.dart'), ('assets/content', '.json')])
    for (final f
        in Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith(ext)))
      for (final r in f.readAsStringSync().runes)
        if (r > 0x7E) r,
};

void main() {
  final ethiopic = {
    for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold'])
      w: fontCodePoints('assets/fonts/NotoSansEthiopic-$w.ttf'),
  };
  final nunito = fontCodePoints('assets/fonts/Nunito-Bold.ttf');

  test('font files are parsed correctly (sanity)', () {
    expect(nunito, containsAll('Helo'.runes.toSet()));
    expect(ethiopic['Regular'], contains('ሰ'.runes.first));
  });

  test('bundled Ethiopic font covers every Ethiopic character used in the app (all weights)', () {
    final used = nonAsciiCharsInLib().where(isEthiopic).toSet();
    expect(
      used.length,
      greaterThan(40),
      reason: 'sanity: Amharic content is present',
    );
    for (final entry in ethiopic.entries) {
      final missing = used.difference(entry.value);
      expect(
        missing.map(String.fromCharCode),
        isEmpty,
        reason: 'missing in NotoSansEthiopic-${entry.key}',
      );
    }
  });

  test(
    'Nunito does NOT contain Ethiopic (so the fallback is genuinely required)',
    () {
      expect(nunito.where(isEthiopic), isEmpty);
    },
  );

  test('every non-ASCII character in the UI is covered by Nunito or the Ethiopic fallback', () {
    final combined = {...nunito, ...ethiopic['Regular']!};
    final missing = nonAsciiCharsInLib()
        .where((c) => !combined.contains(c) && c != 0xFE0F)
        .toList();
    expect(
      missing.map(
        (c) =>
            'U+${c.toRadixString(16).toUpperCase()} "${String.fromCharCode(c)}"',
      ),
      isEmpty,
    );
  });

  group('rendering', () {
    setUpAll(loadAppFonts);

    testWidgets(
      'Amharic text lays out via the bundled fallback without clipping',
      (t) async {
        // Compare word by word: spaces legitimately come from Nunito.
        final samples = {
          for (final term in DemoCourse.terms.values)
            ...term.native.am.split(' '),
          for (final s in DemoCourse.sentences.values)
            ...s.native.am.split(' '),
        };
        for (final text in samples) {
          final viaFallback = TextPainter(
            text: TextSpan(text: text, style: AppType.prompt),
            textDirection: TextDirection.ltr,
          )..layout();
          final direct = TextPainter(
            text: TextSpan(
              text: text,
              style: AppType.prompt.copyWith(
                fontFamily: 'NotoSansEthiopic',
                fontFamilyFallback: const [],
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          // Same advance width ⇒ glyphs came from Noto Sans Ethiopic, not tofu.
          expect(viaFallback.width, closeTo(direct.width, 0.5), reason: text);
          expect(
            viaFallback.width,
            greaterThan(AppType.prompt.fontSize! * 0.5 * text.runes.length),
            reason: text,
          );
          // Single line with a generous line box (1.4x) for tall Ethiopic glyphs.
          expect(viaFallback.computeLineMetrics(), hasLength(1), reason: text);
          expect(
            viaFallback.height,
            greaterThanOrEqualTo(AppType.prompt.fontSize! * 1.35),
            reason: text,
          );
          viaFallback.dispose();
          direct.dispose();
        }
      },
    );

    testWidgets('mixed-script strings render in widgets with no overflow', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: Column(
                children: [
                  Text('ሰላም! Good morning', style: AppType.headline),
                  Text('ዓረፍተ ነገሩን በእንግሊዝኛ ይገንቡ', style: AppType.body),
                  Text('አመሰግናለሁ ጓደኛዬ', style: AppType.prompt),
                ],
              ),
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('አመሰግናለሁ ጓደኛዬ'), findsOneWidget);
    });
  });
}
