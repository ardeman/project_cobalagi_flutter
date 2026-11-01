import 'dart:convert';
import 'dart:math';

import 'exercise_result.dart';
import 'learner_state.dart';
import 'skill_graph.dart';

/// Why a file couldn't be loaded as progress.
enum ProgressFileProblem {
  /// Not a Coba Lagi progress file, or a damaged one.
  notProgress,

  /// Saved by a newer version of the app.
  tooNew,
}

final class ProgressFileException implements Exception {
  const ProgressFileException(this.problem);

  final ProgressFileProblem problem;

  @override
  String toString() => 'ProgressFileException(${problem.name})';
}

/// One child's progress as a file a parent moves to another device: the
/// nickname and avatar, the learning state and every finished exercise.
/// Nothing else leaves the device.
final class ProgressFile {
  const ProgressFile({
    required this.nickname,
    required this.avatar,
    required this.learner,
    this.attempts = const [],
  });

  /// Reads a file written by [encode]. Throws [ProgressFileException].
  factory ProgressFile.decode(String text) {
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, Object?> || json['format'] != format) {
        throw const ProgressFileException(ProgressFileProblem.notProgress);
      }
      if ((json['version']! as int) > version) {
        throw const ProgressFileException(ProgressFileProblem.tooNew);
      }
      return ProgressFile(
        nickname: json['nickname']! as String,
        avatar: json['avatar']! as int,
        learner: LearnerState.fromJson(
          json['learner']! as Map<String, Object?>,
        ),
        attempts: [
          for (final a
              in (json['attempts']! as List).cast<Map<String, Object?>>())
            (
              DateTime.fromMillisecondsSinceEpoch(a['at']! as int),
              ExerciseResult.fromJson(a),
            ),
        ],
      );
    } on ProgressFileException {
      rethrow;
    } on Object {
      // Bad JSON, a missing field or a wrong type: not a file we wrote.
      throw const ProgressFileException(ProgressFileProblem.notProgress);
    }
  }

  static const format = 'cobalagi-progress';

  /// Raised when a change means older apps can't read the file.
  static const version = 1;

  final String nickname;
  final int avatar;
  final LearnerState learner;

  /// Finished exercises with the time each was recorded, oldest first.
  final List<(DateTime, ExerciseResult)> attempts;

  String encode() => jsonEncode({
    'format': format,
    'version': version,
    'nickname': nickname,
    'avatar': avatar,
    'learner': learner.toJson(),
    'attempts': [
      for (final (at, result) in attempts)
        {'at': at.millisecondsSinceEpoch, ...result.toJson()},
    ],
  });

  /// A file name for [day], e.g. `cobalagi-Budi-2026-11-01.json`; characters
  /// file systems dislike become `-`.
  String fileName(DateTime day) {
    final name = nickname.trim().replaceAll(
      RegExp(r'[^\p{L}\p{N}_]+', unicode: true),
      '-',
    );
    String two(int n) => n.toString().padLeft(2, '0');
    return 'cobalagi-${name.isEmpty ? 'player' : name}-'
        '${day.year}-${two(day.month)}-${two(day.day)}.json';
  }
}

/// [here]'s progress with [other]'s added, so nothing earned on either
/// device is lost: each lesson keeps its best stars, lessons solved, puzzles
/// seen, demos and stickers come from both, and each Warm-up game keeps its
/// best level. A concept's mastery and difficulty come from the device that
/// played it more, and the child carries on from whichever is further along
/// (with its bonus adventure and placement). Concepts [graph] doesn't know (a
/// file from a newer app) are left out.
LearnerState mergeLearners(
  LearnerState here,
  LearnerState other, {
  required SkillGraph graph,
}) {
  other = fitToGraph(other, graph, fallback: here.currentConcept);
  final lead =
      graph.indexOf(other.currentConcept) > graph.indexOf(here.currentConcept)
      ? other
      : here;
  return LearnerState(
    currentConcept: lead.currentConcept,
    progress: {
      for (final id in {...here.progress.keys, ...other.progress.keys})
        id: switch ((here.progress[id], other.progress[id])) {
          (final a?, final b?) => _mergeConcept(a, b),
          (final a?, null) => a,
          (null, final b?) => b,
          (null, null) => throw StateError('unreachable'),
        },
    },
    review: lead.review,
    seenPuzzles: {...here.seenPuzzles, ...other.seenPuzzles},
    nextSeed: max(here.nextSeed, other.nextSeed),
    placement: lead.placement,
    tutorialsSeen: {...here.tutorialsSeen, ...other.tutorialsSeen},
    warmUp: {
      ...here.warmUp,
      for (final MapEntry(:key, :value) in other.warmUp.entries)
        key: max(value, here.warmUp[key] ?? 0),
    },
    stickersSeen: {...here.stickersSeen, ...other.stickersSeen},
  );
}

ConceptProgress _mergeConcept(ConceptProgress a, ConceptProgress b) {
  final base = b.exercises > a.exercises ? b : a;
  return base.copyWith(
    attemptedLessons: {...a.attemptedLessons, ...b.attemptedLessons},
    solvedLessons: {...a.solvedLessons, ...b.solvedLessons},
    lessonStars: {
      ...a.lessonStars,
      for (final MapEntry(:key, :value) in b.lessonStars.entries)
        key: max(value, a.lessonStars[key] ?? 0),
    },
  );
}

/// [learner] without concepts [graph] doesn't know. A current concept or
/// bonus adventure it doesn't know falls back to [fallback], without the
/// adventure.
LearnerState fitToGraph(
  LearnerState learner,
  SkillGraph graph, {
  required String fallback,
}) {
  final review = learner.review;
  final known = graph.contains(learner.currentConcept);
  final placement = learner.placement;
  return learner.copyWith(
    currentConcept: known ? null : fallback,
    progress: {
      for (final MapEntry(:key, :value) in learner.progress.entries)
        if (graph.contains(key)) key: value,
    },
    review: () =>
        known &&
            review != null &&
            graph.contains(review.conceptId) &&
            graph.contains(review.returnTo)
        ? review
        : null,
    placement: () => placement == null || graph.contains(placement.startConcept)
        ? placement
        : null,
  );
}
