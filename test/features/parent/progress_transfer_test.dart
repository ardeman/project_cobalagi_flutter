import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/parent/data/progress_transfer.dart';
import 'package:cobalagi/features/profiles/data/profile.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/progress_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Curriculum curriculum;
  late ProgressRepository phone;
  late ProgressRepository tablet;

  setUpAll(() async => curriculum = await CurriculumRepository().load());

  setUp(() async {
    final factory = newDatabaseFactoryMemory();
    phone = ProgressRepository(await factory.openDatabase('phone.db'));
    tablet = ProgressRepository(await factory.openDatabase('tablet.db'));
  });

  final budi = Profile(
    id: 1,
    nickname: 'Budi',
    avatar: 2,
    createdAt: DateTime(2026),
  );

  ExerciseResult solved(String levelId) => ExerciseResult(
    conceptId: levelId.split('-').first,
    levelId: levelId,
    mode: ExerciseMode.lesson,
    difficulty: 1,
    succeeded: true,
    runs: 1,
    hintsUsed: 0,
    duration: const Duration(seconds: 5),
  );

  test('a child moves to another device with their progress', () async {
    final engine = curriculum.engine;
    var learner = engine.initialState();
    for (final id in ['directions-01', 'directions-02']) {
      (learner, _) = engine.record(learner, solved(id));
      await phone.logAttempt(1, solved(id));
    }
    await phone.save(1, learner);

    final saved = await ProgressTransfer(
      progress: phone,
      curriculum: curriculum,
    ).save(budi);
    final file = ProgressFile.decode(saved.encode());
    expect(file.nickname, 'Budi');

    final onTablet = ProgressTransfer(progress: tablet, curriculum: curriculum);
    await onTablet.load(7, file);
    await onTablet.load(7, file);

    final moved = (await tablet.load(7))!;
    expect(moved.progress['directions']!.solvedLessons, {
      'directions-01',
      'directions-02',
    });
    // Loading the same file twice doesn't log its exercises twice.
    expect(await tablet.attempts(7), hasLength(2));
  });

  test('loading adds to what the child already has', () async {
    final engine = curriculum.engine;
    var here = engine.initialState();
    (here, _) = engine.record(here, solved('directions-01'));
    await tablet.save(1, here);
    await tablet.logAttempt(1, solved('directions-01'));

    var there = engine.initialState();
    (there, _) = engine.record(there, solved('directions-02'));
    await ProgressTransfer(progress: tablet, curriculum: curriculum).load(
      1,
      ProgressFile(
        nickname: 'Budi',
        avatar: 0,
        learner: there,
        attempts: [(DateTime(2026, 10), solved('directions-02'))],
      ),
    );

    final merged = (await tablet.load(1))!;
    expect(merged.progress['directions']!.solvedLessons, {
      'directions-01',
      'directions-02',
    });
    expect(await tablet.attempts(1), hasLength(2));
  });
}
