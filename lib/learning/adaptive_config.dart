/// Thresholds for the learning rules, loaded from `assets/config/adaptive.json`.
/// Nothing here has a default in code, so the config file is the only source.
final class AdaptiveConfig {
  const AdaptiveConfig({
    required this.advanceAt,
    required this.practiceAt,
    required this.masteryWindow,
    required this.minExercises,
    required this.reviewAfterFailures,
    required this.reviewLength,
    required this.offerSkipAfterRuns,
    required this.extraRunPenalty,
    required this.hintPenalty,
    required this.slowAfter,
    required this.slowPenalty,
    required this.minSuccessScore,
    required this.startDifficulty,
    required this.maxDifficulty,
  });

  factory AdaptiveConfig.fromJson(Map<String, Object?> json) {
    final score = json['score']! as Map<String, Object?>;
    final difficulty = json['difficulty']! as Map<String, Object?>;
    double d(Map<String, Object?> m, String key) => (m[key]! as num).toDouble();
    int i(Map<String, Object?> m, String key) => m[key]! as int;
    return AdaptiveConfig(
      advanceAt: d(json, 'advanceAt'),
      practiceAt: d(json, 'practiceAt'),
      masteryWindow: i(json, 'masteryWindow'),
      minExercises: i(json, 'minExercises'),
      reviewAfterFailures: i(json, 'reviewAfterFailures'),
      reviewLength: i(json, 'reviewLength'),
      offerSkipAfterRuns: i(json, 'offerSkipAfterRuns'),
      extraRunPenalty: d(score, 'extraRunPenalty'),
      hintPenalty: d(score, 'hintPenalty'),
      slowAfter: Duration(seconds: i(score, 'slowAfterSeconds')),
      slowPenalty: d(score, 'slowPenalty'),
      minSuccessScore: d(score, 'minSuccessScore'),
      startDifficulty: i(difficulty, 'start'),
      maxDifficulty: i(difficulty, 'max'),
    );
  }

  /// Mastery at or above this advances to the next concept.
  final double advanceAt;

  /// Mastery below this (after [minExercises]) sends the child to review.
  final double practiceAt;

  /// How many recent exercises the mastery average covers.
  final int masteryWindow;

  /// Exercises needed on a concept before advancing or reviewing on mastery.
  final int minExercises;

  /// Given-up exercises in a row that trigger a review.
  final int reviewAfterFailures;

  /// Exercises in one review ("bonus adventure").
  final int reviewLength;

  /// Failed runs after which the child may skip the puzzle.
  final int offerSkipAfterRuns;

  final double extraRunPenalty;
  final double hintPenalty;
  final Duration slowAfter;
  final double slowPenalty;
  final double minSuccessScore;
  final int startDifficulty;
  final int maxDifficulty;
}
