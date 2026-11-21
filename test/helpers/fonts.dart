import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's bundled fonts into the test engine so rendered output
/// (and Ethiopic glyph checks) use the real typefaces instead of Ahem boxes.
Future<void> loadAppFonts() async {
  final families = {
    'Nunito': ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black'],
    'NotoSansEthiopic': ['Regular', 'SemiBold', 'Bold', 'ExtraBold'],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final w in entry.value) {
      final bytes = File('assets/fonts/${entry.key}-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
  // Material icons for screenshot fidelity.
  final iconPath = _materialIconsPath();
  if (iconPath != null) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(ByteData.view(File(iconPath).readAsBytesSync().buffer)),
      );
    await loader.load();
  }
}

String? _materialIconsPath() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return null;
  final f = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  return f.existsSync() ? f.path : null;
}
