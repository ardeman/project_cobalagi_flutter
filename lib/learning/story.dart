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

  /// The ending played when the child has finished every planet, the last
  /// being [lastPlanet]: the whole ending the first time, and a short "tank
  /// full again" after a newer version added planets. Both save this id, so
  /// a child never sits through the same ending twice.
  static String fullTank(String lastPlanet) => 'story-full-$lastPlanet';

  /// The scene telling a child who saw an ending that the space wind blew
  /// stars to a planet nobody had found yet, [lastPlanet] being the newest.
  static String newPlanet(String lastPlanet) => 'story-new-$lastPlanet';

  static bool _sawEnding(LearnerState learner) =>
      learner.tutorialsSeen.any((id) => id.startsWith('story-full-'));

  /// Which ending is still to play now that the child has finished every
  /// planet, the last being [lastPlanet]: none once it played for this map.
  static Ending? endingDue(LearnerState learner, String lastPlanet) {
    if (learner.tutorialsSeen.contains(fullTank(lastPlanet))) return null;
    return _sawEnding(learner) ? Ending.fullAgain : Ending.whole;
  }

  /// Whether the "new planet" scene is still to play: the child saw an
  /// ending, and this version has a newer last planet than any ending
  /// played for.
  static bool newPlanetDue(LearnerState learner, String lastPlanet) =>
      _sawEnding(learner) &&
      !learner.tutorialsSeen.contains(fullTank(lastPlanet)) &&
      !learner.tutorialsSeen.contains(newPlanet(lastPlanet));

  /// How full Koba's tank is, 0 to 1, with [finished] of [planets] coding
  /// planets behind the child. Each finished planet's stars fly into it.
  static double tankFill({required int finished, required int planets}) =>
      planets <= 0 ? 0 : (finished / planets).clamp(0, 1).toDouble();
}

/// The ending of the Star fuel story the child gets (see [Story.endingDue]).
enum Ending {
  /// The tank full for the first time: "Thank you, commander!".
  whole,

  /// After planets added later are finished: the stars fly home, and Koba
  /// thanks the commander for the newest planet's skill.
  fullAgain,
}
