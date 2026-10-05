/// One child's progress on one concept.
final class ConceptProgress {
  const ConceptProgress({
    this.scores = const [],
    this.exercises = 0,
    this.failStreak = 0,
    required this.difficulty,
    this.attemptedLessons = const {},
  });

  factory ConceptProgress.fromJson(Map<String, Object?> json) =>
      ConceptProgress(
        scores: [
          for (final s in (json['scores']! as List).cast<num>()) s.toDouble(),
        ],
        exercises: json['exercises']! as int,
        failStreak: json['failStreak']! as int,
        difficulty: json['difficulty']! as int,
        attemptedLessons: {...(json['lessons']! as List).cast<String>()},
      );

  /// Recent exercise scores, newest last, at most the mastery window.
  final List<double> scores;

  /// Exercises since the concept was started or last returned to.
  final int exercises;

  /// Skipped exercises in a row.
  final int failStreak;

  /// Difficulty for generated practice puzzles.
  final int difficulty;

  /// Hand-made lessons already played, solved or skipped.
  final Set<String> attemptedLessons;

  /// Average of recent scores, 0 to 1.
  double get mastery =>
      scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;

  ConceptProgress copyWith({
    List<double>? scores,
    int? exercises,
    int? failStreak,
    int? difficulty,
    Set<String>? attemptedLessons,
  }) => ConceptProgress(
    scores: scores ?? this.scores,
    exercises: exercises ?? this.exercises,
    failStreak: failStreak ?? this.failStreak,
    difficulty: difficulty ?? this.difficulty,
    attemptedLessons: attemptedLessons ?? this.attemptedLessons,
  );

  Map<String, Object?> toJson() => {
    'scores': scores,
    'exercises': exercises,
    'failStreak': failStreak,
    'difficulty': difficulty,
    'lessons': attemptedLessons.toList(),
  };
}

/// A short detour to a prerequisite, presented as a "bonus adventure".
final class ReviewTrip {
  const ReviewTrip({
    required this.conceptId,
    required this.remaining,
    required this.returnTo,
  });

  factory ReviewTrip.fromJson(Map<String, Object?> json) => ReviewTrip(
    conceptId: json['concept']! as String,
    remaining: json['remaining']! as int,
    returnTo: json['returnTo']! as String,
  );

  final String conceptId;
  final int remaining;
  final String returnTo;

  Map<String, Object?> toJson() => {
    'concept': conceptId,
    'remaining': remaining,
    'returnTo': returnTo,
  };
}

/// Everything the learning rules know about a child. Stored per profile.
final class LearnerState {
  const LearnerState({
    required this.currentConcept,
    this.progress = const {},
    this.review,
    this.seenPuzzles = const {},
    this.nextSeed = 0,
  });

  factory LearnerState.fromJson(Map<String, Object?> json) => LearnerState(
    currentConcept: json['current']! as String,
    progress: {
      for (final MapEntry(:key, :value)
          in (json['progress']! as Map<String, Object?>).entries)
        key: ConceptProgress.fromJson(value! as Map<String, Object?>),
    },
    review: switch (json['review']) {
      final Map<String, Object?> trip => ReviewTrip.fromJson(trip),
      _ => null,
    },
    seenPuzzles: {...(json['seen']! as List).cast<String>()},
    nextSeed: json['nextSeed']! as int,
  );

  /// The concept the child is learning (where reviews return to).
  final String currentConcept;
  final Map<String, ConceptProgress> progress;

  /// Set while the child is on a bonus adventure.
  final ReviewTrip? review;

  /// Fingerprints of puzzles already served, so none repeats.
  final Set<String> seenPuzzles;

  /// Seed for the next generated puzzle.
  final int nextSeed;

  /// The concept the next exercise belongs to.
  String get activeConcept => review?.conceptId ?? currentConcept;

  LearnerState copyWith({
    String? currentConcept,
    Map<String, ConceptProgress>? progress,
    ReviewTrip? Function()? review,
    Set<String>? seenPuzzles,
    int? nextSeed,
  }) => LearnerState(
    currentConcept: currentConcept ?? this.currentConcept,
    progress: progress ?? this.progress,
    review: review != null ? review() : this.review,
    seenPuzzles: seenPuzzles ?? this.seenPuzzles,
    nextSeed: nextSeed ?? this.nextSeed,
  );

  Map<String, Object?> toJson() => {
    'current': currentConcept,
    'progress': {
      for (final MapEntry(:key, :value) in progress.entries)
        key: value.toJson(),
    },
    'review': review?.toJson(),
    'seen': seenPuzzles.toList(),
    'nextSeed': nextSeed,
  };
}
