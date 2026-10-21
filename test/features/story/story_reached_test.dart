import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/story_screen.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/story.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryScreen.reached', () {
    test('has the intro alone before any planet', () {
      final names = StoryScreen.reached(
        const LearnerState(
          currentConcept: 'directions',
          tutorialsSeen: {Story.intro},
        ),
      );
      expect(names, ['intro']);
    });

    test('adds every planet reached in map order, demos counting too', () {
      final names = StoryScreen.reached(
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
      expect(names, [
        'intro',
        'arrival-directions',
        'arrival-sequencing',
        'arrival-loops',
      ]);
    });

    test('puts each ending after its planet, the later ones short', () {
      final first = arrivalScenes.keys.elementAt(arrivalScenes.length - 2);
      final last = arrivalScenes.keys.last;
      final names = StoryScreen.reached(
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
      expect(names.skip(arrivalScenes.length), [
        'ending-$first',
        'new-planet-$last',
        'arrival-$last',
        'full-again-$last',
      ]);
    });

    test('adds the planets the warm-up or a parent skipped', () {
      final names = StoryScreen.reached(
        const LearnerState(
          currentConcept: 'loops',
          tutorialsSeen: {Story.intro},
        ),
      );
      expect(names, ['intro', 'arrival-directions', 'arrival-sequencing']);
    });

    test('names only scenes the story screen can play', () {
      final names = StoryScreen.reached(
        LearnerState(
          currentConcept: arrivalScenes.keys.last,
          tutorialsSeen: {
            Story.intro,
            for (final c in arrivalScenes.keys) Story.fullTank(c),
          },
        ),
      );
      expect(names.where((n) => !StoryScreen.scenes.containsKey(n)), isEmpty);
    });
  });
}
