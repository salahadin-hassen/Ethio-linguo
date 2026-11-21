import 'dart:io';
import 'dart:typed_data';

/// Minimal TrueType `cmap` reader: returns every code point the font maps
/// to a glyph (supports subtable formats 4 and 12).
Set<int> fontCodePoints(String path) {
  final data = ByteData.view(File(path).readAsBytesSync().buffer);
  final numTables = data.getUint16(4);
  int? cmapOffset;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes([
      for (var j = 0; j < 4; j++) data.getUint8(rec + j),
    ]);
    if (tag == 'cmap') cmapOffset = data.getUint32(rec + 8);
  }
  if (cmapOffset == null) throw StateError('no cmap in $path');
  final out = <int>{};
  final n = data.getUint16(cmapOffset + 2);
  for (var i = 0; i < n; i++) {
    final sub = cmapOffset + data.getUint32(cmapOffset + 4 + i * 8 + 4);
    final format = data.getUint16(sub);
    if (format == 4) {
      final segX2 = data.getUint16(sub + 6);
      final ends = sub + 14;
      final starts = ends + segX2 + 2;
      final deltas = starts + segX2;
      final ranges = deltas + segX2;
      for (var s = 0; s < segX2 ~/ 2; s++) {
        final end = data.getUint16(ends + s * 2);
        final start = data.getUint16(starts + s * 2);
        final delta = data.getInt16(deltas + s * 2);
        final rangeOffset = data.getUint16(ranges + s * 2);
        for (var c = start; c <= end && c != 0xFFFF; c++) {
          int glyph;
          if (rangeOffset == 0) {
            glyph = (c + delta) & 0xFFFF;
          } else {
            final addr = ranges + s * 2 + rangeOffset + (c - start) * 2;
            glyph = data.getUint16(addr);
            if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
          }
          if (glyph != 0) out.add(c);
        }
      }
    } else if (format == 12) {
      final groups = data.getUint32(sub + 12);
      for (var g = 0; g < groups; g++) {
        final base = sub + 16 + g * 12;
        final start = data.getUint32(base);
        final end = data.getUint32(base + 4);
        for (var c = start; c <= end; c++) {
          out.add(c);
        }
      }
    }
  }
  return out;
}
