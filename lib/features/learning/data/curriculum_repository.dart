import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../engine/world/level.dart';
import '../../../learning/adaptive_config.dart';
import '../../../learning/learning_engine.dart';
import '../../../learning/placement/placement.dart';
import '../../../learning/skill_graph.dart';
import '../../../learning/warm_up/warm_up.dart';
import '../../play/data/level_repository.dart';
import '../../tutorial/data/tutorial.dart';

/// The skill map, the learning thresholds and the hand-made lessons.
final class Curriculum {
  const Curriculum({
    required this.engine,
    required this.lessons,
    required this.placementRules,
    required this.vocabulary,
    required this.pretestSecondChances,
    required this.warmUp,
    this.tutorials = const {},
  });

  final LearningEngine engine;
  final PlacementRules placementRules;

  /// Object and color ids the warm-up game may use.
  final Map<String, Object?> vocabulary;

  /// Extra warm-up questions per skill after a wrong answer.
  final int pretestSecondChances;

  /// The Warm-up island's games and round length.
  final WarmUpConfig warmUp;

  /// Lessons per concept id, in play order.
  final Map<String, List<Level>> lessons;

  /// Each island's "Watch me!" demo, by concept id.
  final Map<String, Tutorial> tutorials;

  Map<String, List<String>> get lessonIds => {
    for (final MapEntry(:key, :value) in lessons.entries)
      key: [for (final level in value) level.id],
  };

  Level? lesson(String id) {
    for (final levels in lessons.values) {
      for (final level in levels) {
        if (level.id == id) return level;
      }
    }
    return null;
  }
}

class CurriculumRepository {
  CurriculumRepository({AssetBundle? bundle, LevelRepository? levels})
    : _bundle = bundle ?? rootBundle,
      _levels = levels ?? LevelRepository(bundle: bundle);

  final AssetBundle _bundle;
  final LevelRepository _levels;
  Future<Curriculum>? _curriculum;

  /// Loaded once, then cached.
  Future<Curriculum> load() => _curriculum ??= _load();

  Future<Curriculum> _load() async {
    Future<Map<String, Object?>> json(String name) async =>
        jsonDecode(await _bundle.loadString('assets/config/$name.json'))
            as Map<String, Object?>;
    final graph = SkillGraph.fromJson(await json('skills'));
    final config = AdaptiveConfig.fromJson(await json('adaptive'));
    final pretest = await json('pretest');
    final rules = PlacementRules.fromJson(
      pretest['placement']! as Map<String, Object?>,
    )..checkAgainst(graph);
    return Curriculum(
      engine: LearningEngine(graph, config),
      lessons: await _levels.loadLessons(),
      placementRules: rules,
      vocabulary: pretest['vocabulary']! as Map<String, Object?>,
      pretestSecondChances: pretest['secondChances']! as int,
      warmUp: WarmUpConfig.fromJson(await json('warm_up')),
      tutorials: parseTutorials(
        await _bundle.loadString('assets/config/tutorials.json'),
      ),
    );
  }
}
