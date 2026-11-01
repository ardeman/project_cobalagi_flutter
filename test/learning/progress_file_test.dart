import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/progress_file.dart';
import 'package:cobalagi/learning/skill_graph.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final graph = SkillGraph([
    const Concept(id: 'directions'),
    const Concept(id: 'sequencing'),
    const Concept(id: 'loops'),
  ]);

  const result = ExerciseResult(
    conceptId: 'directions',
    levelId: 'directions-01',
    mode: ExerciseMode.lesson,
    difficulty: 1,
    succeeded: true,
    runs: 1,
    hintsUsed: 0,
    duration: Duration(seconds: 5),
  );

  group('ProgressFile', () {
    test('reads back what it writes', () {
      final file = ProgressFile(
        nickname: 'Budi',
        avatar: 3,
        learner: const LearnerState(
          currentConcept: 'sequencing',
          progress: {
            'directions': ConceptProgress(
              difficulty: 2,
              exercises: 4,
              solvedLessons: {'directions-01'},
              lessonStars: {'directions-01': 3},
            ),
          },
          warmUp: {'counting': 2},
        ),
        attempts: [(DateTime.fromMillisecondsSinceEpoch(1000), result)],
      );
      final back = ProgressFile.decode(file.encode());
      expect(back.nickname, 'Budi');
      expect(back.avatar, 3);
      expect(back.learner.toJson(), file.learner.toJson());
      expect(back.attempts.single.$1.millisecondsSinceEpoch, 1000);
      expect(back.attempts.single.$2.toJson(), result.toJson());
    });

    test('rejects files that are not progress', () {
      for (final text in ['', 'hello', '[]', '{"format":"other"}']) {
        expect(
          () => ProgressFile.decode(text),
          throwsA(
            isA<ProgressFileException>().having(
              (e) => e.problem,
              'problem',
              ProgressFileProblem.notProgress,
            ),
          ),
        );
      }
      // The right format with a field missing is damaged, not progress.
      expect(
        () => ProgressFile.decode('{"format":"cobalagi-progress","version":1}'),
        throwsA(isA<ProgressFileException>()),
      );
    });

    test('says a file from a newer app is too new', () {
      expect(
        () =>
            ProgressFile.decode('{"format":"cobalagi-progress","version":99}'),
        throwsA(
          isA<ProgressFileException>().having(
            (e) => e.problem,
            'problem',
            ProgressFileProblem.tooNew,
          ),
        ),
      );
    });

    test('names the file after the child and the day', () {
      const learner = LearnerState(currentConcept: 'directions');
      final day = DateTime(2026, 11, 1);
      expect(
        const ProgressFile(
          nickname: 'Budi',
          avatar: 0,
          learner: learner,
        ).fileName(day),
        'cobalagi-Budi-2026-11-01.json',
      );
      expect(
        const ProgressFile(
          nickname: 'Ani / Bu?',
          avatar: 0,
          learner: learner,
        ).fileName(day),
        'cobalagi-Ani-Bu--2026-11-01.json',
      );
    });
  });

  group('mergeLearners', () {
    test('keeps the best of both devices', () {
      const here = LearnerState(
        currentConcept: 'sequencing',
        progress: {
          'directions': ConceptProgress(
            difficulty: 1,
            exercises: 6,
            scores: [1, 1],
            attemptedLessons: {'directions-01', 'directions-02'},
            solvedLessons: {'directions-01', 'directions-02'},
            lessonStars: {'directions-01': 3, 'directions-02': 1},
          ),
        },
        seenPuzzles: {'a'},
        nextSeed: 4,
        tutorialsSeen: {'directions'},
        warmUp: {'counting': 3, 'colours': 1},
        stickersSeen: {'directions'},
      );
      const other = LearnerState(
        currentConcept: 'loops',
        progress: {
          'directions': ConceptProgress(
            difficulty: 3,
            exercises: 9,
            scores: [0.5],
            attemptedLessons: {'directions-03'},
            solvedLessons: {'directions-03'},
            lessonStars: {'directions-02': 2, 'directions-03': 3},
          ),
          'loops': ConceptProgress(difficulty: 1),
        },
        seenPuzzles: {'b'},
        nextSeed: 2,
        tutorialsSeen: {'loops'},
        warmUp: {'counting': 1, 'shapes': 2},
        stickersSeen: {'warmup-counting'},
      );
      final merged = mergeLearners(here, other, graph: graph);
      expect(merged.currentConcept, 'loops');
      final directions = merged.progress['directions']!;
      expect(directions.lessonStars, {
        'directions-01': 3,
        'directions-02': 2,
        'directions-03': 3,
      });
      expect(directions.solvedLessons, hasLength(3));
      expect(directions.attemptedLessons, hasLength(3));
      // Mastery comes from the device that played the concept more.
      expect(directions.exercises, 9);
      expect(directions.scores, [0.5]);
      expect(merged.progress.keys, containsAll(['directions', 'loops']));
      expect(merged.seenPuzzles, {'a', 'b'});
      expect(merged.nextSeed, 4);
      expect(merged.tutorialsSeen, {'directions', 'loops'});
      expect(merged.warmUp, {'counting': 3, 'colours': 1, 'shapes': 2});
      expect(merged.stickersSeen, {'directions', 'warmup-counting'});
    });

    test('carries on from this device when it is further along', () {
      const here = LearnerState(
        currentConcept: 'loops',
        review: ReviewTrip(
          conceptId: 'directions',
          remaining: 2,
          returnTo: 'loops',
        ),
      );
      const other = LearnerState(currentConcept: 'directions');
      final merged = mergeLearners(here, other, graph: graph);
      expect(merged.currentConcept, 'loops');
      expect(merged.review?.conceptId, 'directions');
    });

    test('leaves out concepts this app does not know', () {
      const here = LearnerState(currentConcept: 'sequencing');
      const other = LearnerState(
        currentConcept: 'teach',
        progress: {'teach': ConceptProgress(difficulty: 1)},
      );
      final merged = mergeLearners(here, other, graph: graph);
      expect(merged.currentConcept, 'sequencing');
      expect(merged.progress, isEmpty);
    });
  });
}
