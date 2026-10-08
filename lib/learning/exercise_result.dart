import 'dart:math';

import 'adaptive_config.dart';

enum ExerciseMode {
  /// A hand-made level that introduces the concept.
  lesson,

  /// A generated variation of the current concept.
  practice,

  /// A generated puzzle of a prerequisite, shown as a "bonus adventure".
  review,

  /// A lesson played again from its island, just for fun: it never changes
  /// mastery or what comes next.
  replay,
}

/// What happened in one exercise (one puzzle), recorded when the child solves
/// it or skips it.
final class ExerciseResult {
  const ExerciseResult({
    required this.conceptId,
    required this.levelId,
    required this.mode,
    required this.difficulty,
    required this.succeeded,
    required this.runs,
    required this.hintsUsed,
    required this.duration,
  });

  factory ExerciseResult.fromJson(Map<String, Object?> json) => ExerciseResult(
    conceptId: json['concept']! as String,
    levelId: json['level']! as String,
    mode: ExerciseMode.values.byName(json['mode']! as String),
    difficulty: json['difficulty']! as int,
    succeeded: json['succeeded']! as bool,
    runs: json['runs']! as int,
    hintsUsed: json['hints']! as int,
    duration: Duration(milliseconds: json['ms']! as int),
  );

  final String conceptId;
  final String levelId;
  final ExerciseMode mode;
  final int difficulty;
  final bool succeeded;

  /// Times the child pressed Go or Step to start a run; on success this is the
  /// number of runs it took.
  final int runs;
  final int hintsUsed;
  final Duration duration;

  /// 0 when skipped; otherwise 1, lowered for extra runs, hints and slowness,
  /// but never below [AdaptiveConfig.minSuccessScore].
  double score(AdaptiveConfig config) {
    if (!succeeded) return 0;
    final penalty =
        config.extraRunPenalty * max(0, runs - 1) +
        config.hintPenalty * hintsUsed +
        (duration > config.slowAfter ? config.slowPenalty : 0);
    return max(config.minSuccessScore, 1 - penalty);
  }

  /// A puzzle's stars, 0 to 3: 3 for solving it on the first try without
  /// the hint, 2 within a few tries, 1 for any other solve (thresholds in
  /// `assets/config/adaptive.json`).
  int stars(AdaptiveConfig config) => !succeeded
      ? 0
      : runs <= config.threeStarRuns && hintsUsed == 0
      ? 3
      : runs <= config.twoStarRuns
      ? 2
      : 1;

  Map<String, Object?> toJson() => {
    'concept': conceptId,
    'level': levelId,
    'mode': mode.name,
    'difficulty': difficulty,
    'succeeded': succeeded,
    'runs': runs,
    'hints': hintsUsed,
    'ms': duration.inMilliseconds,
  };
}
