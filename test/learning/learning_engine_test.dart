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
  List<ExerciseResult> results, {
  Map<String, List<String>> lessons = const {},
}) {
  late Decision decision;
  for (final r in results) {
    (state, decision) = engine.record(state, r, lessons: lessons);
  }
  return (state, decision);
}

void main() {
  group('skill graph', () {
    test('follows Directions → … → Variables → Fix it! → Until the flag', () {
      expect(graph.first, 'directions');
      expect(graph.nextAfter('directions'), 'sequencing');
      expect(graph.nextAfter('sequencing'), 'loops');
      expect(graph.nextAfter('loops'), 'functions');
      expect(graph.nextAfter('functions'), 'conditions');
      expect(graph.nextAfter('conditions'), 'variables');
      expect(graph.nextAfter('variables'), 'debugging');
      expect(graph.nextAfter('debugging'), 'until');
      expect(graph.nextAfter('until'), isNull);
      expect(graph.reviewTargetFor('until'), 'loops');
      // Struggling to fix bugs reviews loops, where the bugs come from.
      expect(graph.reviewTargetFor('debugging'), 'loops');
      expect(graph.reviewTargetFor('variables'), 'conditions');
      expect(graph.reviewTargetFor('conditions'), 'functions');
      expect(graph.reviewTargetFor('functions'), 'loops');
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
      final (_, decision) = play(engine.initialState(startConcept: 'until'), [
        for (var i = 0; i < config.minExercises; i++) result('until'),
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

  group('replays', () {
    test('solving a lesson earns its star; skipping does not', () {
      var state = engine.initialState();
      (state, _) = play(state, [
        result('directions', mode: ExerciseMode.lesson, level: 'd1'),
        result(
          'directions',
          mode: ExerciseMode.lesson,
          level: 'd2',
          succeeded: false,
        ),
      ]);
      final progress = engine.progressOf(state, 'directions');
      expect(progress.attemptedLessons, {'d1', 'd2'});
      expect(progress.solvedLessons, {'d1'});
    });

    test('a replay earns a star and changes nothing else', () {
      var state = engine.initialState(startConcept: 'sequencing');
      (state, _) = play(state, [
        result(
          'directions',
          mode: ExerciseMode.lesson,
          level: 'd2',
          succeeded: false,
        ),
      ]);
      final before = engine.progressOf(state, 'directions');
      state = engine.recordReplay(
        state,
        result('directions', mode: ExerciseMode.replay, level: 'd2'),
      );
      final after = engine.progressOf(state, 'directions');
      expect(after.solvedLessons, {'d2'});
      expect(after.scores, before.scores);
      expect(after.exercises, before.exercises);
      expect(after.difficulty, before.difficulty);
      expect(state.currentConcept, 'sequencing');

      final unchanged = engine.recordReplay(
        state,
        result(
          'directions',
          mode: ExerciseMode.replay,
          level: 'd3',
          succeeded: false,
        ),
      );
      expect(identical(unchanged, state), isTrue);
    });

    test('progress saved before stars existed still loads', () {
      final json = const ConceptProgress(difficulty: 2).toJson()
        ..remove('solved');
      expect(ConceptProgress.fromJson(json).solvedLessons, isEmpty);
    });
  });

  group('finishing an island', () {
    final lessons = {
      'directions': [for (var i = 1; i <= 6; i++) 'directions-0$i'],
      'sequencing': [for (var i = 1; i <= 6; i++) 'sequencing-0$i'],
    };
    // Solved, but with three hints and extra tries: a low score.
    ExerciseResult struggled(String concept, {String level = 'generated'}) =>
        result(
          concept,
          hints: 3,
          runs: 3,
          mode: level == 'generated'
              ? ExerciseMode.practice
              : ExerciseMode.lesson,
          level: level,
        );

    test(
      'every lesson solved with hints still leads on to the next island',
      () {
        var (state, decision) = play(engine.initialState(), [
          for (final id in lessons['directions']!)
            struggled('directions', level: id),
        ], lessons: lessons);
        expect(state.currentConcept, 'directions', reason: 'scores are low');
        var practice = 0;
        while (decision is! Advance && practice < 20) {
          (state, decision) = play(state, [
            struggled('directions'),
          ], lessons: lessons);
          practice++;
        }
        expect(decision, isA<Advance>());
        expect(state.currentConcept, 'sequencing');
        // Lessons count too: at most practiceLimit puzzles on the island.
        expect(6 + practice, lessThanOrEqualTo(config.practiceLimit));
        expect(practice, greaterThan(0), reason: 'some practice first');
      },
    );

    test('without the lessons done, low scores do not move a child on', () {
      final (state, decision) = play(engine.initialState(), [
        for (var i = 0; i < 10; i++) struggled('directions'),
      ], lessons: lessons);
      expect(decision, isNot(isA<Advance>()));
      expect(state.currentConcept, 'directions');
    });

    test('a given-up puzzle never moves a child on', () {
      var (state, _) = play(engine.initialState(), [
        for (final id in lessons['directions']!)
          struggled('directions', level: id),
      ], lessons: lessons);
      final (after, decision) = play(state, [
        for (var i = 0; i < 4; i++) result('directions', succeeded: false),
      ], lessons: lessons);
      expect(decision, isNot(isA<Advance>()));
      expect(after.currentConcept, 'directions');
    });
  });
}
