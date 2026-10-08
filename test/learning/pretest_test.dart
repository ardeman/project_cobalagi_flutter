import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/learning/adaptive_config.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/learning_engine.dart';
import 'package:cobalagi/learning/placement/placement.dart';
import 'package:cobalagi/learning/placement/pretest_generator.dart';
import 'package:cobalagi/learning/placement/pretest_question.dart';
import 'package:cobalagi/learning/placement/pretest_session.dart';
import 'package:cobalagi/learning/skill_graph.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

final pretest = readJson('assets/config/pretest.json');
final rules = PlacementRules.fromJson(
  pretest['placement']! as Map<String, Object?>,
);
final graph = SkillGraph.fromJson(readJson('assets/config/skills.json'));

PretestGenerator generator(int seed) => PretestGenerator.fromJson(
  pretest['vocabulary']! as Map<String, Object?>,
  Random(seed),
);

Program program(List<InstructionKind> kinds) => Program([
  for (final k in kinds)
    switch (k) {
      InstructionKind.move => const Move(),
      InstructionKind.turnLeft => const TurnLeft(),
      InstructionKind.turnRight => const TurnRight(),
      InstructionKind.repeat ||
      InstructionKind.ifPathClear ||
      InstructionKind.untilGoal ||
      InstructionKind.ifElse ||
      InstructionKind.setSteps ||
      InstructionKind.moveSteps ||
      InstructionKind.call => throw ArgumentError(),
    },
]);

/// Answers right while the skill's level is at most [ceiling].
void playTo(PretestSession session, Map<PretestSkill, int> ceiling) {
  for (var q = session.current; q != null; q = session.current) {
    final right = q.level <= (ceiling[q.skill] ?? 0);
    session.answer(right ? q.correct : (q.correct + 1) % q.optionCount);
  }
}

void main() {
  group('questions', () {
    for (final skill in PretestSkill.values) {
      for (var level = 1; level <= maxSkillLevel; level++) {
        test('${skill.name} level $level is well formed', () {
          for (var seed = 0; seed < 30; seed++) {
            final q = generator(seed).question(skill, level);
            expect(q.skill, skill);
            expect(q.level, level);
            expect(q.optionCount, greaterThanOrEqualTo(2));
            expect(q.correct, inInclusiveRange(0, q.optionCount - 1));
            switch (q) {
              case ReadingQuestion(:final words, :final options):
                expect(options[q.correct], words);
                expect(options.toSet(), hasLength(options.length));
              case CountingQuestion(:final count, :final options):
                expect(options[q.correct], count);
                expect(options.toSet(), hasLength(options.length));
              case SideQuestion(:final target):
                expect(q.correct, target.index);
              case TurnQuestion(:final facing, :final turn, :final options):
                final expected = turn == Side.left ? facing.left : facing.right;
                expect(options[q.correct], expected);
                expect(options.toSet(), hasLength(options.length));
              case PatternQuestion(:final options):
                expect(options.toSet(), hasLength(options.length));
              case SequencingQuestion(:final map, :final options):
                for (var i = 0; i < options.length; i++) {
                  expect(
                    runProgram(program(options[i]), map).succeeded,
                    i == q.correct,
                    reason: 'only the right option reaches the flag',
                  );
                }
              case ColorQuestion() || ShapeQuestion():
                fail('the warm-up game asks no colour or shape questions');
            }
          }
        });
      }
    }

    test('pattern answers continue the shown cycle', () {
      final q =
          generator(3).question(PretestSkill.pattern, 1) as PatternQuestion;
      // AB AB AB → A
      expect(q.options[q.correct], q.sequence[0]);
    });
  });

  group('session', () {
    final checkpoints = rules.checkpoints;
    PretestSession session(int seed, {int secondChances = 1}) => PretestSession(
      generator(seed),
      secondChances: secondChances,
      checkpoints: checkpoints,
    );

    test('asks only the levels placement looks at', () {
      expect(checkpoints, {
        PretestSkill.reading: [2],
        PretestSkill.direction: [2],
        PretestSkill.pattern: [2],
        PretestSkill.sequencing: [3, 1],
      });
      // Counting is left to the Warm-up island.
      expect(session(1).skills, isNot(contains(PretestSkill.counting)));
    });

    test('all right is one question per skill and places furthest', () {
      final s = session(2);
      playTo(s, {for (final skill in PretestSkill.values) skill: 3});
      expect(s.questionsAsked, 4);
      expect(s.progress, 1);
      expect(rules.place(s.levels, at: DateTime(2026)).startConcept, 'loops');
      expect(rules.place(s.levels, at: DateTime(2026)).readsWords, isTrue);
    });

    test('all wrong stays short: a second chance, then the next level', () {
      final s = session(3);
      playTo(s, {});
      // Two each for reading, directions and patterns; steps tries 3, then 1.
      expect(s.questionsAsked, 2 + 2 + 2 + 4);
      expect(s.levels.values.every((l) => l == 0), isTrue);
      expect(
        rules.place(s.levels, at: DateTime(2026)).startConcept,
        'directions',
      );
    });

    test('missing the top step level still counts the lower one', () {
      final s = session(4);
      playTo(s, {PretestSkill.direction: 2, PretestSkill.sequencing: 2});
      expect(s.levels[PretestSkill.sequencing], 1);
      expect(
        rules.place(s.levels, at: DateTime(2026)).startConcept,
        'sequencing',
      );
    });

    test('a second chance at the same level can still count', () {
      final s = session(5);
      final first = s.current!;
      s.answer((first.correct + 1) % first.optionCount);
      expect(s.current!.skill, first.skill);
      expect(s.current!.level, first.level);
      s.answer(s.current!.correct);
      expect(s.levels[first.skill], first.level);
      expect(s.current!.skill, isNot(first.skill));
    });

    test('never asks more than 10 questions, whatever the answers', () {
      for (var seed = 0; seed < 2000; seed++) {
        final s = session(seed);
        final random = Random(seed);
        var asked = 0;
        while (!s.isFinished) {
          final q = s.current!;
          s.answer(
            random.nextBool() ? q.correct : (q.correct + 1) % q.optionCount,
          );
          asked++;
        }
        expect(asked, lessThanOrEqualTo(10), reason: 'seed $seed');
        expect(asked, greaterThanOrEqualTo(4), reason: 'seed $seed');
      }
    });

    test('without second chances one wrong answer moves on', () {
      final s = session(6, secondChances: 0);
      playTo(s, {});
      expect(s.questionsAsked, 1 + 1 + 1 + 2);
    });
  });

  group('placement', () {
    test('rules name concepts on the skill map', () {
      expect(() => rules.checkAgainst(graph), returnsNormally);
    });

    Placement place(Map<PretestSkill, int> levels) =>
        rules.place(levels, at: DateTime(2026));

    test('strong pre-skills start further along', () {
      expect(
        place({
          PretestSkill.direction: 3,
          PretestSkill.sequencing: 3,
          PretestSkill.pattern: 2,
        }).startConcept,
        'loops',
      );
      expect(
        place({
          PretestSkill.direction: 2,
          PretestSkill.sequencing: 1,
        }).startConcept,
        'sequencing',
      );
      expect(place({}).startConcept, 'directions');
    });

    test('reading level decides word blocks', () {
      expect(place({PretestSkill.reading: 1}).readsWords, isFalse);
      expect(place({PretestSkill.reading: 2}).readsWords, isTrue);
    });

    test('applying a placement moves the start and survives JSON', () {
      final engine = LearningEngine(
        graph,
        AdaptiveConfig.fromJson(readJson('assets/config/adaptive.json')),
      );
      final placed = engine.applyPlacement(
        engine.initialState(),
        place({PretestSkill.direction: 2, PretestSkill.sequencing: 2}),
      );
      expect(placed.currentConcept, 'sequencing');
      final copy = LearnerState.fromJson(
        jsonDecode(jsonEncode(placed.toJson())) as Map<String, Object?>,
      );
      expect(copy.placement!.startConcept, 'sequencing');
      expect(copy.placement!.levels[PretestSkill.direction], 2);
    });

    test('states saved before placement existed still load', () {
      final json = const LearnerState(currentConcept: 'loops').toJson()
        ..remove('placement');
      expect(LearnerState.fromJson(json).placement, isNull);
    });
  });
}
