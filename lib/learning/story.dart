import 'exercise_result.dart';
import 'learner_state.dart';

/// The Star fuel story: Koba's ship runs on stars, a space wind scattered
/// them over the planets, and the child helps collect them. Each scene plays
/// once per child, saved in [LearnerState.tutorialsSeen] under its id.
abstract final class Story {
  /// The intro, played on the map once the child has a starting point.
  static const intro = 'story-intro';

  /// Whether the intro is still to play: after the warm-up (or a parent's
  /// pick) places the child, and also for children who already had progress
  /// before the story existed.
  static bool introDue(LearnerState learner) =>
      learner.placement != null && !learner.tutorialsSeen.contains(intro);

  /// The arrival scene of the planet [conceptId]: why Koba needs its skill,
  /// played before the planet's "Watch me!" demo.
  static String arrival(String conceptId) => 'story-arrival-$conceptId';

  /// Whether the planet [conceptId]'s arrival is still to play: only on the
  /// first visit, while its demo hasn't been seen either (children who
  /// explored a planet before the story don't get it late), and never in a
  /// bonus adventure or a replay.
  static bool arrivalDue(
    LearnerState learner,
    String conceptId,
    ExerciseMode mode,
  ) =>
      (mode == ExerciseMode.lesson || mode == ExerciseMode.practice) &&
      !learner.tutorialsSeen.contains(conceptId) &&
      !learner.tutorialsSeen.contains(arrival(conceptId));

  /// How full Koba's tank is, 0 to 1, with [finished] of [planets] coding
  /// planets behind the child. Each finished planet's stars fly into it.
  static double tankFill({required int finished, required int planets}) =>
      planets <= 0 ? 0 : (finished / planets).clamp(0, 1).toDouble();
}
