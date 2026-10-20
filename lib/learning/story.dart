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

  /// How full Koba's tank is, 0 to 1, with [finished] of [planets] coding
  /// planets behind the child. Each finished planet's stars fly into it.
  static double tankFill({required int finished, required int planets}) =>
      planets <= 0 ? 0 : (finished / planets).clamp(0, 1).toDouble();
}
