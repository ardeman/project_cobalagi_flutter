import 'dart:math';

import 'adaptive_config.dart';
import 'exercise_result.dart';
import 'learner_state.dart';
import 'skill_graph.dart';

/// What happens after an exercise. The UI frames every one positively;
/// [Review] in particular is a "bonus adventure", never a failure.
sealed class Decision {
  const Decision();
}

/// Mastered [from]; moving on to [to].
final class Advance extends Decision {
  const Advance(this.from, this.to);

  final String from;
  final String to;
}

/// Stay on [conceptId] with a new puzzle.
final class Practice extends Decision {
  const Practice(this.conceptId);

  final String conceptId;
}

/// A short detour to the prerequisite [conceptId] before returning.
final class Review extends Decision {
  const Review(this.conceptId, {required this.returnTo});

  final String conceptId;
  final String returnTo;
}

/// The bonus adventure is over; back to [conceptId].
final class ReturnFromReview extends Decision {
  const ReturnFromReview(this.conceptId);

  final String conceptId;
}

/// Mastered the last concept on the map; keep practising it.
final class MapComplete extends Decision {
  const MapComplete(this.conceptId);

  final String conceptId;
}

/// Which puzzle to serve next.
final class ExercisePlan {
  const ExercisePlan({
    required this.conceptId,
    required this.mode,
    required this.difficulty,
    this.lessonId,
  });

  final String conceptId;
  final ExerciseMode mode;
  final int difficulty;

  /// The hand-made level for [ExerciseMode.lesson]; otherwise null and the
  /// puzzle is generated.
  final String? lessonId;
}

/// The rule-based adaptive learning loop. Pure and deterministic.
final class LearningEngine {
  const LearningEngine(this.graph, this.config);

  final SkillGraph graph;
  final AdaptiveConfig config;

  LearnerState initialState({String? startConcept}) {
    final start = startConcept ?? graph.first;
    if (!graph.contains(start)) throw SkillGraphException('unknown $start');
    return LearnerState(currentConcept: start);
  }

  ConceptProgress progressOf(LearnerState state, String conceptId) =>
      state.progress[conceptId] ??
      ConceptProgress(difficulty: config.startDifficulty);

  /// Picks the next exercise: unplayed lessons of the active concept first
  /// (not during a review), then generated puzzles.
  ExercisePlan nextExercise(
    LearnerState state, {
    required Map<String, List<String>> lessons,
  }) {
    final conceptId = state.activeConcept;
    final progress = progressOf(state, conceptId);
    if (state.review == null) {
      for (final id in lessons[conceptId] ?? const <String>[]) {
        if (!progress.attemptedLessons.contains(id)) {
          return ExercisePlan(
            conceptId: conceptId,
            mode: ExerciseMode.lesson,
            difficulty: progress.difficulty,
            lessonId: id,
          );
        }
      }
    }
    return ExercisePlan(
      conceptId: conceptId,
      mode: state.review == null ? ExerciseMode.practice : ExerciseMode.review,
      difficulty: progress.difficulty,
    );
  }

  /// Remembers a served puzzle so it is never served again.
  LearnerState markServed(LearnerState state, String fingerprint, int seed) =>
      state.copyWith(
        seenPuzzles: {...state.seenPuzzles, fingerprint},
        nextSeed: max(state.nextSeed, seed + 1),
      );

  /// Updates progress with [result] and decides what comes next.
  (LearnerState, Decision) record(LearnerState state, ExerciseResult result) {
    final updated = _withResult(state, result);
    final review = updated.review;

    if (review != null && result.conceptId == review.conceptId) {
      if (review.remaining > 1) {
        return (
          updated.copyWith(
            review: () => ReviewTrip(
              conceptId: review.conceptId,
              remaining: review.remaining - 1,
              returnTo: review.returnTo,
            ),
          ),
          Review(review.conceptId, returnTo: review.returnTo),
        );
      }
      return (
        updated.copyWith(currentConcept: review.returnTo, review: () => null),
        ReturnFromReview(review.returnTo),
      );
    }

    final conceptId = updated.currentConcept;
    final progress = progressOf(updated, conceptId);
    final enoughData = progress.exercises >= config.minExercises;

    final struggling =
        progress.failStreak >= config.reviewAfterFailures ||
        (enoughData && progress.mastery < config.practiceAt);
    if (struggling) {
      final target = graph.reviewTargetFor(conceptId);
      if (target != null) {
        // Coming back after the review starts a fresh count, so the child is
        // not sent straight back on the first puzzle.
        final fresh = progress.copyWith(
          scores: [],
          exercises: 0,
          failStreak: 0,
        );
        return (
          updated.copyWith(
            progress: {...updated.progress, conceptId: fresh},
            review: () => ReviewTrip(
              conceptId: target,
              remaining: config.reviewLength,
              returnTo: conceptId,
            ),
          ),
          Review(target, returnTo: conceptId),
        );
      }
      return (updated, Practice(conceptId));
    }

    if (enoughData && progress.mastery >= config.advanceAt) {
      final next = graph.nextAfter(conceptId);
      if (next == null) return (updated, MapComplete(conceptId));
      return (updated.copyWith(currentConcept: next), Advance(conceptId, next));
    }
    return (updated, Practice(conceptId));
  }

  LearnerState _withResult(LearnerState state, ExerciseResult result) {
    final old = progressOf(state, result.conceptId);
    final score = result.score(config);
    final scores = [...old.scores, score];
    final step = !result.succeeded || score < config.practiceAt
        ? -1
        : score >= config.advanceAt
        ? 1
        : 0;
    final progress = old.copyWith(
      scores: scores.sublist(max(0, scores.length - config.masteryWindow)),
      exercises: old.exercises + 1,
      failStreak: result.succeeded ? 0 : old.failStreak + 1,
      difficulty: (old.difficulty + step).clamp(1, config.maxDifficulty),
      attemptedLessons: result.mode == ExerciseMode.lesson
          ? {...old.attemptedLessons, result.levelId}
          : old.attemptedLessons,
    );
    return state.copyWith(
      progress: {...state.progress, result.conceptId: progress},
    );
  }
}
