/// A skill-map concept, e.g. `loops`, and the concepts it builds on.
final class Concept {
  const Concept({required this.id, this.prerequisites = const []});

  final String id;
  final List<String> prerequisites;
}

class SkillGraphException implements Exception {
  const SkillGraphException(this.message);

  final String message;

  @override
  String toString() => 'SkillGraphException: $message';
}

/// Concepts in teaching order. Every prerequisite must be listed before the
/// concept that needs it, which also rules out cycles.
final class SkillGraph {
  SkillGraph(List<Concept> concepts) : concepts = List.unmodifiable(concepts) {
    final seen = <String>{};
    for (final concept in concepts) {
      for (final prerequisite in concept.prerequisites) {
        if (!seen.contains(prerequisite)) {
          throw SkillGraphException(
            '${concept.id} needs $prerequisite, which must be listed earlier',
          );
        }
      }
      if (!seen.add(concept.id)) {
        throw SkillGraphException('duplicate concept ${concept.id}');
      }
    }
    if (concepts.isEmpty) throw const SkillGraphException('no concepts');
  }

  /// Parses `{"concepts": [{"id": ..., "prerequisites": [...]}, ...]}`.
  factory SkillGraph.fromJson(Map<String, Object?> json) => SkillGraph([
    for (final c in (json['concepts']! as List).cast<Map<String, Object?>>())
      Concept(
        id: c['id']! as String,
        prerequisites: [
          ...((c['prerequisites'] as List?) ?? const []).cast<String>(),
        ],
      ),
  ]);

  final List<Concept> concepts;

  String get first => concepts.first.id;

  bool contains(String id) => concepts.any((c) => c.id == id);

  int indexOf(String id) => concepts.indexWhere((c) => c.id == id);

  Concept operator [](String id) => concepts.firstWhere(
    (c) => c.id == id,
    orElse: () => throw SkillGraphException('unknown concept $id'),
  );

  /// The next concept to learn after [id]: the first later concept that
  /// builds on it, or null at the end of the map.
  String? nextAfter(String id) {
    for (final concept in concepts.skip(indexOf(id) + 1)) {
      if (concept.prerequisites.contains(id)) return concept.id;
    }
    return null;
  }

  /// Where a struggling child goes for a review: the first prerequisite.
  String? reviewTargetFor(String id) {
    final prerequisites = this[id].prerequisites;
    return prerequisites.isEmpty ? null : prerequisites.first;
  }
}
