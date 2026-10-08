import 'adaptive_config.dart';
import 'exercise_result.dart';
import 'learner_state.dart';

/// How far a child is on one concept, as a parent sees it.
enum ConceptStatus { notStarted, practising, mastered }

/// One concept (island) in a [ProgressReport].
final class ConceptReport {
  const ConceptReport({
    required this.conceptId,
    required this.status,
    required this.stars,
    required this.solvedLessons,
    required this.totalLessons,
  });

  final String conceptId;
  final ConceptStatus status;

  /// The stars the adventure map shows for this island, 0 to 3.
  final int stars;

  /// Hand-made levels solved at least once, of [totalLessons].
  final int solvedLessons;
  final int totalLessons;
}

/// A parent's summary of one child's learning, built from the learner state
/// and the log of finished exercises.
final class ProgressReport {
  const ProgressReport({
    required this.concepts,
    required this.puzzlesSolved,
    required this.playTime,
    required this.weekPuzzlesSolved,
    required this.weekPlayTime,
    required this.lastPlayed,
  });

  /// Builds the report. [conceptIds] are in skill-map order, [lessons] maps
  /// each concept to its hand-made levels' ids, and [attempts] are
  /// the finished exercises with the time they were recorded.
  factory ProgressReport.build({
    required List<String> conceptIds,
    required LearnerState learner,
    required AdaptiveConfig config,
    required Map<String, List<String>> lessons,
    required List<(DateTime, ExerciseResult)> attempts,
    required DateTime now,
  }) {
    final weekStart = now.subtract(const Duration(days: 7));
    var solved = 0;
    var weekSolved = 0;
    var time = Duration.zero;
    var weekTime = Duration.zero;
    DateTime? last;
    for (final (at, result) in attempts) {
      final thisWeek = !at.isBefore(weekStart);
      time += result.duration;
      if (thisWeek) weekTime += result.duration;
      if (result.succeeded) {
        solved++;
        if (thisWeek) weekSolved++;
      }
      if (last == null || at.isAfter(last)) last = at;
    }
    return ProgressReport(
      concepts: [
        for (final id in conceptIds)
          _concept(id, learner.progress[id], lessons[id] ?? const []),
      ],
      puzzlesSolved: solved,
      playTime: time,
      weekPuzzlesSolved: weekSolved,
      weekPlayTime: weekTime,
      lastPlayed: last,
    );
  }

  final List<ConceptReport> concepts;

  /// Puzzles solved since the child started, replays included.
  final int puzzlesSolved;

  /// Time spent on finished puzzles since the child started.
  final Duration playTime;

  /// [puzzlesSolved] and [playTime] for the last 7 days.
  final int weekPuzzlesSolved;
  final Duration weekPlayTime;

  /// Null until the first puzzle is finished.
  final DateTime? lastPlayed;

  /// An island's stars on the map and in the report: the average of its
  /// levels' stars (an unplayed level counts 0), rounded down, so three
  /// stars means every level earned three.
  static int starsFor(ConceptProgress? progress, List<String> lessons) {
    if (progress == null || lessons.isEmpty) return 0;
    final total = lessons.fold(0, (sum, id) => sum + progress.starsOf(id));
    return total ~/ lessons.length;
  }

  static ConceptReport _concept(
    String id,
    ConceptProgress? progress,
    List<String> lessons,
  ) {
    final stars = starsFor(progress, lessons);
    final totalLessons = lessons.length;
    return ConceptReport(
      conceptId: id,
      status: switch (stars) {
        0 when (progress?.attemptedLessons.isEmpty ?? true) =>
          ConceptStatus.notStarted,
        3 => ConceptStatus.mastered,
        _ => ConceptStatus.practising,
      },
      stars: stars,
      solvedLessons: progress?.solvedLessons.length ?? 0,
      totalLessons: totalLessons,
    );
  }
}
