import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/learning/exercise_result.dart';
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
}
