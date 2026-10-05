import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../engine/world/level.dart';

/// Hand-made lesson packs, one per concept, named after the concept id.
const levelPacks = ['directions', 'sequencing', 'loops'];

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
  Future<Map<String, List<Level>>>? _lessons;

  /// Lessons per concept id, in play order. Loaded once, then cached.
  Future<Map<String, List<Level>>> loadLessons() => _lessons ??= _load();

  Future<Map<String, List<Level>>> _load() async => {
    for (final pack in levelPacks)
      pack: parseLevelPack(
        await _bundle.loadString('assets/levels/$pack.json'),
      ),
  };
}
