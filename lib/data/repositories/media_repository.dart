import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/media.dart';

// SHARED CONTRACT — see docs/INTEGRATION_CONTRACTS.md §5.
// Implementation owner: Engineer 2 (media learning).

/// Read-only catalogue of learnable media. The MVP reads bundled assets only.
abstract interface class MediaRepository {
  Future<List<MediaItem>> list();
  Future<MediaItem?> byId(String id);
}

/// Loads `assets/content/media/index.json`, which lists one JSON manifest per
/// clip (schema: docs/INTEGRATION_CONTRACTS.md §3). Works fully offline.
class AssetMediaRepository implements MediaRepository {
  AssetMediaRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const indexPath = 'assets/content/media/index.json';
  final AssetBundle _bundle;
  List<MediaItem>? _cache;

  @override
  Future<List<MediaItem>> list() async {
    if (_cache != null) return _cache!;
    final index = jsonDecode(await _bundle.loadString(indexPath)) as Map;
    final items = <MediaItem>[];
    for (final path in (index['items'] as List).cast<String>()) {
      final j = jsonDecode(await _bundle.loadString(path)) as Map;
      items.add(MediaItem.fromJson(j.cast<String, Object?>()));
    }
    return _cache = items;
  }

  @override
  Future<MediaItem?> byId(String id) async {
    for (final m in await list()) {
      if (m.id == id) return m;
    }
    return null;
  }
}

class InMemoryMediaRepository implements MediaRepository {
  const InMemoryMediaRepository(this.items);

  final List<MediaItem> items;

  @override
  Future<List<MediaItem>> list() async => items;

  @override
  Future<MediaItem?> byId(String id) async {
    for (final m in items) {
      if (m.id == id) return m;
    }
    return null;
  }
}
