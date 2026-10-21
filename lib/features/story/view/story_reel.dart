import 'dart:ui';

import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/ending_scenes.dart';
import 'package:cobalagi/features/story/view/intro_scene.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/story.dart';

/// The story so far, played by the map's book button: every scene the child
/// has reached, one after another as one scene, in the order they played.
class StoryReel extends StoryScene {
  StoryReel(this.scenes)
    : beats = [for (final scene in scenes) ...scene.beats],
      _starts = [
        for (
          var i = 0, at = 0;
          i < scenes.length;
          at += scenes[i].beats.length, i++
        )
          at,
      ];

  /// The scenes the child has reached, in story order: the intro, then
  /// each planet's (the "new planet" scene that announced it, its arrival,
  /// and the ending its stars completed).
  ///
  /// A planet counts as reached once its arrival or demo played, and also
  /// when the child is past it on the map: the warm-up or a parent may have
  /// started them further on, so they never saw the planets before.
  factory StoryReel.reached(LearnerState learner) {
    final seen = learner.tutorialsSeen;
    final current = arrivalScenes.keys.toList().indexOf(learner.currentConcept);
    final scenes = <StoryScene>[const IntroScene()];
    var sawEnding = false;
    var i = 0;
    for (final MapEntry(:key, :value) in arrivalScenes.entries) {
      if (seen.contains(Story.newPlanet(key))) scenes.add(NewPlanetScene(key));
      if (i++ < current || seen.contains(value.id) || seen.contains(key)) {
        scenes.add(value);
      }
      if (seen.contains(Story.fullTank(key))) {
        scenes.add(sawEnding ? FullAgainScene(key) : EndingScene(key));
        sawEnding = true;
      }
    }
    return StoryReel(scenes);
  }

  /// Never saved: replaying marks nothing as seen.
  static const replayId = 'story-replay';

  final List<StoryScene> scenes;

  @override
  final List<StoryBeat> beats;

  /// Where each scene's beats begin in [beats].
  final List<int> _starts;

  @override
  String get id => replayId;

  @override
  void paint(Canvas canvas, Rect stage, StoryFrame frame, StoryArt? art) {
    var i = scenes.length - 1;
    while (i > 0 && _starts[i] > frame.beat) {
      i--;
    }
    scenes[i].paint(
      canvas,
      stage,
      StoryFrame(beat: frame.beat - _starts[i], t: frame.t, time: frame.time),
      art,
    );
  }
}
