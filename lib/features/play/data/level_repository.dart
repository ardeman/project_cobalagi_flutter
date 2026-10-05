import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../engine/world/level.dart';

/// Hand-made level packs, played in this order.
const levelPacks = ['directions', 'sequencing'];

/// Parses a pack file: `{"levels": [<level JSON>, ...]}`.
List<Level> parseLevelPack(String source) {
  final json = jsonDecode(source) as Map<String, Object?>;
  return [
    for (final level in (json['levels']! as List).cast<Map<String, Object?>>())
      Level.fromJson(level),
  ];
}

class LevelRepository {
  LevelRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<List<Level>>? _levels;

  /// All hand-made levels in play order. Loaded once, then cached.
  Future<List<Level>> loadAll() => _levels ??= _load();

  Future<List<Level>> _load() async => [
    for (final pack in levelPacks)
      ...parseLevelPack(await _bundle.loadString('assets/levels/$pack.json')),
  ];
}
