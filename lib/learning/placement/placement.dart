import '../skill_graph.dart';
import 'pretest_question.dart';

/// Where a child starts, from the warm-up game or set by a parent.
final class Placement {
  const Placement({
    required this.startConcept,
    required this.levels,
    required this.readsWords,
    required this.at,
    this.byParent = false,
  });

  factory Placement.fromJson(Map<String, Object?> json) => Placement(
    startConcept: json['start']! as String,
    levels: {
      for (final MapEntry(:key, :value)
          in (json['levels']! as Map<String, Object?>).entries)
        PretestSkill.values.byName(key): value! as int,
    },
    readsWords: json['readsWords']! as bool,
    at: DateTime.fromMillisecondsSinceEpoch(json['at']! as int),
    byParent: json['byParent'] as bool? ?? false,
  );

  final String startConcept;

  /// Pretest result per skill, 0 to 3; empty when a parent set the start.
  final Map<PretestSkill, int> levels;

  /// Whether the child can read words, from the warm-up game. Kept for
  /// choosing what readers see; the blocks themselves are always pictures.
  final bool readsWords;
  final DateTime at;
  final bool byParent;

  Map<String, Object?> toJson() => {
    'start': startConcept,
    'levels': {for (final e in levels.entries) e.key.name: e.value},
    'readsWords': readsWords,
    'at': at.millisecondsSinceEpoch,
    'byParent': byParent,
  };
}

/// Placement thresholds from `assets/config/pretest.json`. Rules are checked
/// in order; the first whose minimums are all met picks the start.
final class PlacementRules {
  PlacementRules({
    required this.readsWordsAt,
    required this.rules,
    required this.fallback,
  });

  factory PlacementRules.fromJson(Map<String, Object?> json) => PlacementRules(
    readsWordsAt: json['readsWordsAt']! as int,
    rules: [
      for (final rule in (json['rules']! as List).cast<Map<String, Object?>>())
        (
          start: rule['start']! as String,
          minimum: {
            for (final MapEntry(:key, :value)
                in (rule['minimum']! as Map<String, Object?>).entries)
              PretestSkill.values.byName(key): value! as int,
          },
        ),
    ],
    fallback: json['fallback']! as String,
  );

  final int readsWordsAt;
  final List<({String start, Map<PretestSkill, int> minimum})> rules;
  final String fallback;

  /// Throws if a rule names a concept that isn't on the skill map.
  void checkAgainst(SkillGraph graph) {
    for (final start in [fallback, for (final r in rules) r.start]) {
      if (!graph.contains(start)) {
        throw SkillGraphException('placement starts at unknown concept $start');
      }
    }
  }

  /// The only levels placement looks at, per skill, highest first: every
  /// rule's minimums, and [readsWordsAt] for reading. The first warm-up
  /// asks just these, so it stays short; skills no rule needs (counting)
  /// are left to the Warm-up island.
  Map<PretestSkill, List<int>> get checkpoints {
    final levels = <PretestSkill, Set<int>>{
      PretestSkill.reading: {readsWordsAt},
    };
    for (final rule in rules) {
      for (final MapEntry(:key, :value) in rule.minimum.entries) {
        (levels[key] ??= {}).add(value);
      }
    }
    return {
      for (final skill in PretestSkill.values)
        if (levels[skill] case final set? when set.isNotEmpty)
          skill: set.toList()..sort((a, b) => b - a),
    };
  }

  Placement place(Map<PretestSkill, int> levels, {required DateTime at}) {
    var start = fallback;
    for (final rule in rules) {
      final met = rule.minimum.entries.every(
        (m) => (levels[m.key] ?? 0) >= m.value,
      );
      if (met) {
        start = rule.start;
        break;
      }
    }
    return Placement(
      startConcept: start,
      levels: levels,
      readsWords: (levels[PretestSkill.reading] ?? 0) >= readsWordsAt,
      at: at,
    );
  }
}
