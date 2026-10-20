import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/placement/placement.dart';
import 'package:cobalagi/learning/story.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final placed = Placement(
    startConcept: 'directions',
    levels: const {},
    readsWords: false,
    at: DateTime(2026, 10, 20),
    byParent: false,
  );

  group('Story.introDue', () {
    test('waits until the child has a starting point', () {
      expect(
        Story.introDue(const LearnerState(currentConcept: 'directions')),
        isFalse,
      );
    });

    test('plays once placed, also for children with progress', () {
      expect(
        Story.introDue(
          LearnerState(currentConcept: 'loops', placement: placed),
        ),
        isTrue,
      );
    });

    test('plays only once', () {
      expect(
        Story.introDue(
          LearnerState(
            currentConcept: 'loops',
            placement: placed,
            tutorialsSeen: const {Story.intro},
          ),
        ),
        isFalse,
      );
    });
  });

  group('Story.arrivalDue', () {
    final learner = LearnerState(currentConcept: 'loops', placement: placed);

    test('plays on the first visit to a planet', () {
      expect(Story.arrivalDue(learner, 'loops', ExerciseMode.lesson), isTrue);
      expect(Story.arrivalDue(learner, 'loops', ExerciseMode.practice), isTrue);
    });

    test('never in a bonus adventure or a replay', () {
      expect(Story.arrivalDue(learner, 'loops', ExerciseMode.review), isFalse);
      expect(Story.arrivalDue(learner, 'loops', ExerciseMode.replay), isFalse);
    });

    test('plays once, and not late for a planet already explored', () {
      for (final seen in [Story.arrival('loops'), 'loops']) {
        expect(
          Story.arrivalDue(
            learner.copyWith(tutorialsSeen: {seen}),
            'loops',
            ExerciseMode.lesson,
          ),
          isFalse,
          reason: seen,
        );
      }
    });
  });

  test('the tank fills by planets finished out of all planets', () {
    expect(Story.tankFill(finished: 0, planets: 9), 0);
    expect(Story.tankFill(finished: 3, planets: 9), closeTo(1 / 3, 1e-9));
    expect(Story.tankFill(finished: 9, planets: 9), 1);
    // A newer version with more planets never overfills it.
    expect(Story.tankFill(finished: 12, planets: 9), 1);
    expect(Story.tankFill(finished: 0, planets: 0), 0);
  });

  group('the ending', () {
    final learner = LearnerState(
      currentConcept: 'otherwise',
      placement: placed,
    );

    test('the whole ending plays once the last planet is finished', () {
      expect(Story.endingDue(learner, 'otherwise'), Ending.whole);
      expect(
        Story.endingDue(
          learner.copyWith(tutorialsSeen: {Story.fullTank('otherwise')}),
          'otherwise',
        ),
        isNull,
      );
    });

    test('a newer last planet brings the new planet scene, then the short '
        'ending', () {
      final sawEnding = learner.copyWith(
        tutorialsSeen: {Story.fullTank('otherwise')},
      );
      expect(Story.newPlanetDue(sawEnding, 'otherwise'), isFalse);
      expect(Story.newPlanetDue(sawEnding, 'rockets'), isTrue);
      expect(
        Story.newPlanetDue(
          sawEnding.copyWith(
            tutorialsSeen: {
              ...sawEnding.tutorialsSeen,
              Story.newPlanet('rockets'),
            },
          ),
          'rockets',
        ),
        isFalse,
      );
      expect(Story.endingDue(sawEnding, 'rockets'), Ending.fullAgain);
      final again = sawEnding.copyWith(
        tutorialsSeen: {...sawEnding.tutorialsSeen, Story.fullTank('rockets')},
      );
      expect(Story.endingDue(again, 'rockets'), isNull);
      expect(Story.newPlanetDue(again, 'rockets'), isFalse);
    });

    test('no new planet scene before any ending', () {
      expect(Story.newPlanetDue(learner, 'otherwise'), isFalse);
    });
  });
}
