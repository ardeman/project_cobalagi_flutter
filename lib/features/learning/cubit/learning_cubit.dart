import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../engine/generator/puzzle_generator.dart';
import '../../../engine/world/level.dart';
import '../../../learning/exercise_result.dart';
import '../../../learning/learner_state.dart';
import '../../../learning/learning_engine.dart';
import '../../../learning/placement/pretest_generator.dart';
import '../../../learning/placement/pretest_question.dart';
import '../../../learning/placement/pretest_session.dart';
import '../data/curriculum_repository.dart';
import '../data/progress_repository.dart';

/// A puzzle ready to play.
final class Exercise {
  const Exercise({required this.plan, required this.level, required this.key});

  final ExercisePlan plan;
  final Level level;

  /// Unique per served exercise, so the play view rebuilds for each one.
  final String key;
}

class LearningState {
  const LearningState({this.learner, this.lastDecision});

  /// Null until loaded.
  final LearnerState? learner;
  final Decision? lastDecision;
}

/// Runs the learning loop for one child and saves every step.
class LearningCubit extends Cubit<LearningState> {
  LearningCubit({
    required this.profileId,
    required this.curriculum,
    required ProgressRepository progress,
  }) : _progress = progress,
       super(const LearningState());

  final int profileId;
  final Curriculum curriculum;
  final ProgressRepository _progress;
  var _served = 0;

  /// Tries this many seeds before accepting a repeat puzzle.
  static const _maxSeedTries = 50;

  LearningEngine get engine => curriculum.engine;

  Future<void> load() async {
    final saved = await _progress.load(profileId);
    emit(LearningState(learner: saved ?? engine.initialState()));
  }

  /// The next puzzle: a lesson, or a generated one never served before.
  ///
  /// Safe to call while building: the state update is emitted afterwards.
  Exercise nextExercise() {
    var learner = _pending ?? state.learner!;
    final plan = engine.nextExercise(learner, lessons: curriculum.lessonIds);
    late Level level;
    if (plan.lessonId case final id?) {
      level = curriculum.lesson(id)!;
    } else {
      final kind = PuzzleKind.values.byName(plan.conceptId);
      var seed = learner.nextSeed;
      for (var i = 0; ; i++, seed++) {
        level = generatePuzzle(
          kind,
          difficulty: plan.difficulty,
          seed: seed,
        ).level;
        if (!learner.seenPuzzles.contains(level.fingerprint) ||
            i == _maxSeedTries) {
          break;
        }
      }
      learner = engine.markServed(learner, level.fingerprint, seed);
      _pending = learner;
      Future.microtask(() {
        if (isClosed || !identical(_pending, learner)) return;
        emit(LearningState(learner: learner, lastDecision: state.lastDecision));
      });
      _progress.save(profileId, learner);
    }
    return Exercise(plan: plan, level: level, key: '${_served++}-${level.id}');
  }

  /// A served-puzzle update not yet emitted.
  LearnerState? _pending;

  /// A lesson to play again from its island, or null if [levelId] isn't one.
  Exercise? replayExercise(String levelId) {
    final level = curriculum.lesson(levelId);
    if (level == null) return null;
    return Exercise(
      plan: ExercisePlan(
        conceptId: level.concept,
        mode: ExerciseMode.replay,
        difficulty: engine.progressOf(state.learner!, level.concept).difficulty,
        lessonId: levelId,
      ),
      level: level,
      key: '${_served++}-replay-$levelId',
    );
  }

  /// Records a replay. It never changes what comes next, so there is no
  /// decision.
  Future<Decision?> recordReplay(ExerciseResult result) async {
    final current = _pending ?? state.learner!;
    _pending = null;
    final learner = engine.recordReplay(current, result);
    emit(LearningState(learner: learner, lastDecision: state.lastDecision));
    await _progress.logAttempt(profileId, result);
    await _progress.save(profileId, learner);
    return null;
  }

  /// A fresh warm-up game with new questions.
  PretestSession startPretest() => PretestSession(
    PretestGenerator.fromJson(curriculum.vocabulary, Random()),
    secondChances: curriculum.pretestSecondChances,
  );

  /// Places the child from the warm-up game result and saves it.
  Future<void> completePretest(Map<PretestSkill, int> levels) async {
    final placement = curriculum.placementRules.place(
      levels,
      at: DateTime.now(),
    );
    final current = _pending ?? state.learner!;
    _pending = null;
    final learner = engine.applyPlacement(current, placement);
    emit(LearningState(learner: learner));
    await _progress.save(profileId, learner);
  }

  /// Records a solved or skipped exercise and returns what comes next.
  Future<Decision> record(ExerciseResult result) async {
    final current = _pending ?? state.learner!;
    _pending = null;
    final (learner, decision) = engine.record(current, result);
    emit(LearningState(learner: learner, lastDecision: decision));
    await _progress.logAttempt(profileId, result);
    await _progress.save(profileId, learner);
    return decision;
  }
}
