import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/learning_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

ExerciseResult resultFor(Exercise e, {bool succeeded = true}) => ExerciseResult(
  conceptId: e.plan.conceptId,
  levelId: e.level.id,
  mode: e.plan.mode,
  difficulty: e.plan.difficulty,
  succeeded: succeeded,
  runs: 1,
  hintsUsed: 0,
  duration: const Duration(seconds: 10),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Curriculum curriculum;
  late ProgressRepository progress;

  setUpAll(() async => curriculum = await CurriculumRepository().load());

  setUp(() async {
    final db = await newDatabaseFactoryMemory().openDatabase('t.db');
    progress = ProgressRepository(db);
  });

  Future<LearningCubit> newCubit() async {
    final cubit = LearningCubit(
      profileId: 1,
      curriculum: curriculum,
      progress: progress,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  test('starts with the first lesson of the first concept', () async {
    final cubit = await newCubit();
    final exercise = cubit.nextExercise();
    expect(exercise.plan.mode, ExerciseMode.lesson);
    expect(exercise.level.id, 'directions-01');
  });

  test('strong play advances to the next concept and is saved', () async {
    final cubit = await newCubit();
    Decision? decision;
    while (decision is! Advance) {
      decision = await cubit.record(resultFor(cubit.nextExercise()));
    }
    expect(decision.to, 'sequencing');

    final reloaded = await newCubit();
    expect(reloaded.state.learner!.currentConcept, 'sequencing');
    expect(await progress.attempts(1), hasLength(3));
  });

  test('a new island is celebrated once on the map', () async {
    final cubit = await newCubit();
    expect(cubit.state.islandToCelebrate, isNull);
    Decision? decision;
    while (decision is! Advance) {
      decision = await cubit.record(resultFor(cubit.nextExercise()));
    }
    expect(cubit.state.islandToCelebrate, 'sequencing');
    // Other updates keep it until the map has shown it.
    await cubit.markTutorialSeen('sequencing');
    expect(cubit.state.islandToCelebrate, 'sequencing');
    cubit.celebrated();
    expect(cubit.state.islandToCelebrate, isNull);
    expect(cubit.state.learner!.currentConcept, 'sequencing');
  });

  test('generated puzzles never repeat', () async {
    final cubit = await newCubit();
    // Use up the lessons so practice puzzles are generated.
    final fingerprints = <String>{};
    for (var i = 0; i < 12; i++) {
      final exercise = cubit.nextExercise();
      if (exercise.plan.mode != ExerciseMode.lesson) {
        expect(fingerprints.add(exercise.level.fingerprint), isTrue);
      }
      await cubit.record(resultFor(exercise, succeeded: false));
    }
    expect(fingerprints, isNotEmpty);
  });

  test('deleting a profile removes its progress', () async {
    final cubit = await newCubit();
    await cubit.record(resultFor(cubit.nextExercise()));
    await progress.deleteFor(1);
    expect(await progress.load(1), isNull);
    expect(await progress.attempts(1), isEmpty);
  });

  test('every concept has lessons that match it', () {
    for (final concept in curriculum.engine.graph.concepts) {
      final List<Level> lessons = curriculum.lessons[concept.id]!;
      expect(lessons, isNotEmpty);
      expect(lessons.every((l) => l.concept == concept.id), isTrue);
    }
  });

  for (final concept in ['conditions', 'variables']) {
    test('$concept practice skips saved fingerprints after reloading', () async {
      await progress.save(
        1,
        curriculum.engine
            .initialState(startConcept: concept)
            .copyWith(
              progress: {
                concept: ConceptProgress(
                  difficulty: 1,
                  attemptedLessons: curriculum.lessonIds[concept]!.toSet(),
                ),
              },
            ),
      );
      final cubit = await newCubit();
      final first = cubit.nextExercise();
      expect(first.plan.mode, ExerciseMode.practice);
      await cubit.record(resultFor(first));
      final reloaded = await newCubit();
      final second = reloaded.nextExercise();
      expect(second.plan.conceptId, concept);
      expect(second.level.fingerprint, isNot(first.level.fingerprint));
      expect(
        reloaded.state.learner!.seenPuzzles,
        contains(first.level.fingerprint),
      );
      // Flush the served-state update and persistence before closing the Cubit.
      await reloaded.record(resultFor(second));
    });
  }

  test('a replay is logged but never changes what comes next', () async {
    final cubit = await newCubit();
    final first = cubit.nextExercise();
    await cubit.record(resultFor(first));
    final before = cubit.state.learner!;

    final replay = cubit.replayExercise('directions-01')!;
    expect(replay.plan.mode, ExerciseMode.replay);
    expect(replay.level.id, 'directions-01');
    final decision = await cubit.recordReplay(resultFor(replay));

    expect(decision, isNull);
    final after = cubit.state.learner!;
    expect(after.currentConcept, before.currentConcept);
    expect(
      after.progress['directions']!.scores,
      before.progress['directions']!.scores,
    );
    expect(await progress.attempts(1), hasLength(2));
    expect(cubit.replayExercise('not-a-level'), isNull);
  });
}
