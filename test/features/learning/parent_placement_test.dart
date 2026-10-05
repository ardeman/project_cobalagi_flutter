import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/parent_placement.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Curriculum curriculum;
  late ParentPlacement placement;
  late ProgressRepository progress;

  setUpAll(() async => curriculum = await CurriculumRepository().load());

  setUp(() async {
    progress = ProgressRepository(
      await newDatabaseFactoryMemory().openDatabase('t.db'),
    );
    placement = ParentPlacement(progress: progress, curriculum: curriculum);
  });

  test('a parent can set the start, which is marked as theirs', () async {
    await placement.setStart(1, 'loops');
    final learner = (await progress.load(1))!;
    expect(learner.currentConcept, 'loops');
    expect(learner.placement!.byParent, isTrue);
  });

  test(
    'replaying the warm-up game clears placement but keeps progress',
    () async {
      final engine = curriculum.engine;
      var learner = engine.initialState();
      (learner, _) = engine.record(
        learner,
        const ExerciseResult(
          conceptId: 'directions',
          levelId: 'directions-01',
          mode: ExerciseMode.lesson,
          difficulty: 1,
          succeeded: true,
          runs: 1,
          hintsUsed: 0,
          duration: Duration(seconds: 5),
        ),
      );
      await progress.save(1, learner);
      await placement.setStart(1, 'sequencing');
      await placement.retakePretest(1);

      final reloaded = (await progress.load(1))!;
      expect(reloaded.placement, isNull);
      expect(reloaded.progress['directions']!.exercises, 1);
    },
  );
}
