import '../../../learning/learner_state.dart';
import '../../../learning/placement/placement.dart';
import 'curriculum_repository.dart';
import 'progress_repository.dart';

/// Placement changes a parent makes from the parent area.
class ParentPlacement {
  const ParentPlacement({required this.progress, required this.curriculum});

  final ProgressRepository progress;
  final Curriculum curriculum;

  Future<LearnerState> load(int profileId) async =>
      await progress.load(profileId) ?? curriculum.engine.initialState();

  /// Overrides where the child plays next. Progress is kept.
  Future<void> setStart(int profileId, String conceptId) async {
    final engine = curriculum.engine;
    final current = await load(profileId);
    await progress.save(
      profileId,
      engine.applyPlacement(
        current,
        Placement(
          startConcept: conceptId,
          levels: current.placement?.levels ?? const {},
          readsWords: current.placement?.readsWords ?? false,
          at: DateTime.now(),
          byParent: true,
        ),
      ),
    );
  }

  /// Word blocks (Tier 2) or picture blocks (Tier 1) for this child. Kept
  /// until the warm-up game is played again.
  Future<void> setWordBlocks(int profileId, {required bool words}) async {
    final current = await load(profileId);
    final placement = current.placement;
    await progress.save(
      profileId,
      current.copyWith(
        placement: () => Placement(
          startConcept: placement?.startConcept ?? current.currentConcept,
          levels: placement?.levels ?? const {},
          readsWords: words,
          at: placement?.at ?? DateTime.now(),
          byParent: placement?.byParent ?? true,
        ),
      ),
    );
  }

  /// The child plays the warm-up game again next time. Progress is kept.
  Future<void> retakePretest(int profileId) async {
    final current = await load(profileId);
    await progress.save(profileId, current.copyWith(placement: () => null));
  }
}
