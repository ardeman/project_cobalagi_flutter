import '../../../learning/progress_file.dart';
import '../../learning/data/curriculum_repository.dart';
import '../../learning/data/progress_repository.dart';
import '../../profiles/data/profile.dart';

/// Saving a child's progress to a file and loading one, from the parent
/// area. Loading adds to what the child has on this device; it never takes
/// anything away.
class ProgressTransfer {
  const ProgressTransfer({required this.progress, required this.curriculum});

  final ProgressRepository progress;
  final Curriculum curriculum;

  Future<ProgressFile> save(Profile profile) async => ProgressFile(
    nickname: profile.nickname,
    avatar: profile.avatar,
    learner:
        await progress.load(profile.id) ?? curriculum.engine.initialState(),
    attempts: await progress.attemptLog(profile.id),
  );

  Future<void> load(int profileId, ProgressFile file) async {
    final engine = curriculum.engine;
    final here = await progress.load(profileId);
    await progress.save(
      profileId,
      here == null
          ? fitToGraph(file.learner, engine.graph, fallback: engine.graph.first)
          : mergeLearners(here, file.learner, graph: engine.graph),
    );
    await progress.addAttempts(profileId, file.attempts);
  }
}
