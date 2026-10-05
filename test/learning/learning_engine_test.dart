import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/learning/adaptive_config.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/learning_engine.dart';
import 'package:cobalagi/learning/skill_graph.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

final graph = SkillGraph.fromJson(readJson('assets/config/skills.json'));
final config = AdaptiveConfig.fromJson(readJson('assets/config/adaptive.json'));
final engine = LearningEngine(graph, config);

ExerciseResult result(
  String concept, {
  bool succeeded = true,
  int runs = 1,
  int hints = 0,
  int seconds = 20,
  ExerciseMode mode = ExerciseMode.practice,
  String level = 'generated',
}) => ExerciseResult(
  conceptId: concept,
  levelId: level,
  mode: mode,
  difficulty: 1,
  succeeded: succeeded,
  runs: runs,
  hintsUsed: hints,
  duration: Duration(seconds: seconds),
);

/// Records [results] in order and returns the final state and decision.
(LearnerState, Decision) play(
  LearnerState state,
  List<ExerciseResult> results,
) {
  late Decision decision;
  for (final r in results) {
    (state, decision) = engine.record(state, r);
  }
  return (state, decision);
}

void main() {
  group('skill graph', () {
    test('follows Directions → Sequencing → Loops', () {
      expect(graph.first, 'directions');
      expect(graph.nextAfter('directions'), 'sequencing');
      expect(graph.nextAfter('sequencing'), 'loops');
      expect(graph.nextAfter('loops'), isNull);
      expect(graph.reviewTargetFor('loops'), 'sequencing');
      expect(graph.reviewTargetFor('directions'), isNull);
    });

    test('rejects prerequisites listed later and duplicates', () {
      expect(
        () => SkillGraph([
          const Concept(id: 'b', prerequisites: ['a']),
          const Concept(id: 'a'),
        ]),
        throwsA(isA<SkillGraphException>()),
      );
      expect(
        () => SkillGraph([const Concept(id: 'a'), const Concept(id: 'a')]),
        throwsA(isA<SkillGraphException>()),
      );
    });
  });

  group('score', () {
    test('first-run success without hints scores 1', () {
      expect(result('loops').score(config), 1);
    });

    test('extra runs, hints and slowness lower the score', () {
      final s = result('loops', runs: 3, hints: 1, seconds: 500).score(config);
      expect(s, closeTo(1 - 2 * 0.15 - 0.2 - 0.1, 1e-9));
    });

    test('success never scores below the floor; skipping scores 0', () {
      expect(result('loops', runs: 40).score(config), config.minSuccessScore);
      expect(result('loops', succeeded: false).score(config), 0);
    });
  });

  group('decisions', () {
    test('strong results advance after the minimum exercises', () {
      final start = engine.initialState();
      var (state, decision) = play(start, [result('directions')]);
      expect(decision, isA<Practice>());
      (state, decision) = play(state, [
        result('directions'),
        result('directions'),
      ]);
      expect(decision, isA<Advance>());
      expect((decision as Advance).to, 'sequencing');
      expect(state.currentConcept, 'sequencing');
    });

    test('middling results keep practising', () {
      final start = engine.initialState(startConcept: 'sequencing');
      final (state, decision) = play(start, [
        for (var i = 0; i < 5; i++) result('sequencing', runs: 2, hints: 1),
      ]);
      expect(decision, isA<Practice>());
      expect(state.currentConcept, 'sequencing');
    });

    test(
      'struggling goes on a bonus review of the prerequisite and returns',
      () {
        final start = engine.initialState(startConcept: 'loops');
        var (state, decision) = play(start, [
          result('loops', succeeded: false),
          result('loops', succeeded: false),
        ]);
        expect(decision, isA<Review>());
        expect((decision as Review).conceptId, 'sequencing');
        expect(state.activeConcept, 'sequencing');
        expect(state.currentConcept, 'loops');

        for (var i = 1; i < config.reviewLength; i++) {
          (state, decision) = play(state, [result('sequencing')]);
          expect(decision, isA<Review>());
        }
        (state, decision) = play(state, [result('sequencing')]);
        expect(decision, isA<ReturnFromReview>());
        expect(state.review, isNull);
        expect(state.activeConcept, 'loops');

        // A fresh start on return: one more puzzle doesn't re-trigger a review.
        (state, decision) = play(state, [result('loops', runs: 6)]);
        expect(decision, isA<Practice>());
      },
    );

    test('low mastery after enough exercises also triggers a review', () {
      final start = engine.initialState(startConcept: 'sequencing');
      final (_, decision) = play(start, [
        for (var i = 0; i < config.minExercises; i++)
          result('sequencing', runs: 6),
      ]);
      expect(decision, isA<Review>());
    });

    test('the first concept has no review; it keeps practising', () {
      final (_, decision) = play(engine.initialState(), [
        result('directions', succeeded: false),
        result('directions', succeeded: false),
      ]);
      expect(decision, isA<Practice>());
    });

    test('mastering the last concept completes the map', () {
      final (_, decision) = play(engine.initialState(startConcept: 'loops'), [
        for (var i = 0; i < config.minExercises; i++) result('loops'),
      ]);
      expect(decision, isA<MapComplete>());
    });

    test('difficulty rises with strong results and falls when skipping', () {
      var state = engine.initialState();
      (state, _) = play(state, [result('directions'), result('directions')]);
      expect(engine.progressOf(state, 'directions').difficulty, 3);
      (state, _) = play(state, [result('directions', succeeded: false)]);
      expect(engine.progressOf(state, 'directions').difficulty, 2);
    });
  });

  group('exercise plan', () {
    const lessons = {
      'directions': ['d1', 'd2'],
    };

    test('serves unplayed lessons first, then generated practice', () {
      var state = engine.initialState();
      var plan = engine.nextExercise(state, lessons: lessons);
      expect((plan.mode, plan.lessonId), (ExerciseMode.lesson, 'd1'));

      (state, _) = play(state, [
        result('directions', mode: ExerciseMode.lesson, level: 'd1'),
        result(
          'directions',
          mode: ExerciseMode.lesson,
          level: 'd2',
          succeeded: false,
        ),
      ]);
      plan = engine.nextExercise(state, lessons: lessons);
      expect(plan.mode, ExerciseMode.practice);
      expect(plan.lessonId, isNull);
    });

    test('reviews are generated puzzles of the prerequisite', () {
      var state = engine.initialState(startConcept: 'sequencing');
      (state, _) = play(state, [
        result('sequencing', succeeded: false),
        result('sequencing', succeeded: false),
      ]);
      final plan = engine.nextExercise(state, lessons: lessons);
      expect(plan.conceptId, 'directions');
      expect(plan.mode, ExerciseMode.review);
      expect(plan.lessonId, isNull);
    });

    test('served puzzles are remembered and seeds move forward', () {
      final state = engine.markServed(engine.initialState(), 'fp', 7);
      expect(state.seenPuzzles, {'fp'});
      expect(state.nextSeed, 8);
    });
  });

  test('state and results survive a JSON round trip', () {
    var state = engine.initialState(startConcept: 'loops');
    (state, _) = play(state, [
      result('loops', succeeded: false),
      result('loops', succeeded: false),
    ]);
    state = engine.markServed(state, 'fp', 3);
    final copy = LearnerState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>,
    );
    expect(copy.toJson(), state.toJson());

    final r = result('loops', runs: 2, hints: 1);
    expect(ExerciseResult.fromJson(r.toJson()).toJson(), r.toJson());
  });
}
