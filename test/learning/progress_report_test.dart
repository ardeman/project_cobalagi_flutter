import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/learning/adaptive_config.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/progress_report.dart';
import 'package:flutter_test/flutter_test.dart';

final config = AdaptiveConfig.fromJson(
  jsonDecode(File('assets/config/adaptive.json').readAsStringSync())
      as Map<String, Object?>,
);

ExerciseResult result({bool succeeded = true, int seconds = 60}) =>
    ExerciseResult(
      conceptId: 'directions',
      levelId: 'd1',
      mode: ExerciseMode.lesson,
      difficulty: 1,
      succeeded: succeeded,
      runs: 1,
      hintsUsed: 0,
      duration: Duration(seconds: seconds),
    );

void main() {
  final now = DateTime(2026, 10, 6, 12);

  ProgressReport build({
    Map<String, ConceptProgress> progress = const {},
    List<(DateTime, ExerciseResult)> attempts = const [],
  }) => ProgressReport.build(
    conceptIds: const ['directions', 'sequencing', 'loops'],
    learner: LearnerState(currentConcept: 'directions', progress: progress),
    config: config,
    lessonCounts: const {'directions': 4, 'sequencing': 5, 'loops': 6},
    attempts: attempts,
    now: now,
  );

  test('a new child has nothing played and no islands started', () {
    final report = build();
    expect(report.puzzlesSolved, 0);
    expect(report.playTime, Duration.zero);
    expect(report.lastPlayed, isNull);
    expect(report.concepts.map((c) => c.status), [
      ConceptStatus.notStarted,
      ConceptStatus.notStarted,
      ConceptStatus.notStarted,
    ]);
    expect(report.concepts.map((c) => c.totalLessons), [4, 5, 6]);
  });

  test('islands follow the map stars: mastered, practising, started', () {
    final report = build(
      progress: {
        'directions': const ConceptProgress(
          scores: [1, 1, 0.9],
          difficulty: 2,
          solvedLessons: {'d1', 'd2', 'd3', 'd4'},
        ),
        'sequencing': const ConceptProgress(
          scores: [0.6],
          difficulty: 1,
          solvedLessons: {'s1'},
        ),
        // Played a lesson but skipped it: started, no score yet.
        'loops': const ConceptProgress(difficulty: 1, attemptedLessons: {'l1'}),
      },
    );
    final [directions, sequencing, loops] = report.concepts;
    expect(directions.status, ConceptStatus.mastered);
    expect(directions.stars, 3);
    expect(directions.solvedLessons, 4);
    expect(sequencing.status, ConceptStatus.practising);
    expect(sequencing.stars, 2);
    expect(loops.status, ConceptStatus.practising);
    expect(loops.stars, 0);
  });

  test('counts solved puzzles and play time, all time and last 7 days', () {
    final report = build(
      attempts: [
        (now.subtract(const Duration(days: 10)), result(seconds: 120)),
        (now.subtract(const Duration(days: 2)), result(seconds: 90)),
        (
          now.subtract(const Duration(days: 1)),
          result(succeeded: false, seconds: 30),
        ),
        (now.subtract(const Duration(hours: 1)), result(seconds: 60)),
      ],
    );
    expect(report.puzzlesSolved, 3);
    expect(report.playTime, const Duration(seconds: 300));
    expect(report.weekPuzzlesSolved, 2);
    expect(report.weekPlayTime, const Duration(seconds: 180));
    expect(report.lastPlayed, now.subtract(const Duration(hours: 1)));
  });

  test('stars match the adventure map rule', () {
    expect(ProgressReport.starsFor(null, config), 0);
    expect(
      ProgressReport.starsFor(
        const ConceptProgress(scores: [0.2], difficulty: 1),
        config,
      ),
      1,
    );
  });
}
