import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/ending_scenes.dart';
import 'package:cobalagi/features/story/view/intro_scene.dart';
import 'package:cobalagi/features/story/view/story_reel.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/story.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryReel.reached', () {
    test('plays the intro alone before any planet', () {
      final reel = StoryReel.reached(
        const LearnerState(
          currentConcept: 'directions',
          tutorialsSeen: {Story.intro},
        ),
      );
      expect(reel.scenes.single, isA<IntroScene>());
      expect(reel.beats, hasLength(const IntroScene().beats.length));
    });

    test('adds every planet reached in map order, demos counting too', () {
      final reel = StoryReel.reached(
        LearnerState(
          currentConcept: 'directions',
          tutorialsSeen: {
            Story.intro,
            // Explored before the story existed: only its demo was seen.
            'sequencing',
            Story.arrival('directions'),
            Story.arrival('loops'),
          },
        ),
      );
      expect(reel.scenes.map((s) => s.id), [
        Story.intro,
        Story.arrival('directions'),
        Story.arrival('sequencing'),
        Story.arrival('loops'),
      ]);
      expect(
        reel.beats,
        hasLength(reel.scenes.fold<int>(0, (n, s) => n + s.beats.length)),
      );
    });

    test('puts each ending after its planet, the later ones short', () {
      final first = arrivalScenes.keys.elementAt(arrivalScenes.length - 2);
      final last = arrivalScenes.keys.last;
      final reel = StoryReel.reached(
        LearnerState(
          currentConcept: last,
          tutorialsSeen: {
            Story.intro,
            Story.fullTank(first),
            Story.newPlanet(last),
            Story.arrival(last),
            Story.fullTank(last),
          },
        ),
      );
      expect(reel.scenes.skip(arrivalScenes.length).map((s) => s.runtimeType), [
        EndingScene,
        NewPlanetScene,
        arrivalScenes[last]!.runtimeType,
        FullAgainScene,
      ]);
    });

    test('adds the planets the warm-up or a parent skipped', () {
      final reel = StoryReel.reached(
        const LearnerState(
          currentConcept: 'loops',
          tutorialsSeen: {Story.intro},
        ),
      );
      expect(reel.scenes.map((s) => s.id), [
        Story.intro,
        Story.arrival('directions'),
        Story.arrival('sequencing'),
      ]);
    });
  });
}
