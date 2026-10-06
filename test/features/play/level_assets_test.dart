import 'dart:io';

import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/play/data/level_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Searches for `prefix + repeat(times, unit) + suffix` versions of the
/// straight-line [steps] that fit [maxBlocks].
Program? withOneRepeat(List<Instruction> steps, int maxBlocks) {
  for (var start = 0; start < steps.length; start++) {
    for (var unit = 1; start + unit * 2 <= steps.length; unit++) {
      var times = 1;
      bool sameAs(int k) => List.generate(
        unit,
        (j) => steps[start + j].kind == steps[start + k * unit + j].kind,
      ).every((same) => same);
      while (start + (times + 1) * unit <= steps.length && sameAs(times)) {
        times++;
      }
      final body = steps.sublist(start, start + unit);
      final rest = steps.sublist(start + times * unit);
      // The run stops on the goal, so a final repeat may end part-way.
      final restIsPartialUnit =
          rest.isNotEmpty &&
          rest.length < unit &&
          List.generate(
            rest.length,
            (j) => rest[j].kind == body[j].kind,
          ).every((same) => same);
      for (final program in [
        if (times >= 2)
          Program([...steps.sublist(0, start), Repeat(times, body), ...rest]),
        if (restIsPartialUnit && times + 1 >= 2)
          Program([...steps.sublist(0, start), Repeat(times + 1, body)]),
      ]) {
        if (program.blockCount <= maxBlocks) return program;
      }
    }
  }
  return null;
}

/// Searches for a star block (a run of [steps]) that, called wherever it
/// fits, makes the program fit [maxBlocks].
Program? withOneProcedure(List<Instruction> steps, int maxBlocks) {
  bool same(List<Instruction> a, int at) =>
      at + a.length <= steps.length &&
      List.generate(
        a.length,
        (j) => a[j].kind == steps[at + j].kind,
      ).every((s) => s);
  for (var unit = 2; unit <= steps.length ~/ 2; unit++) {
    for (var start = 0; start + unit <= steps.length; start++) {
      final procedure = steps.sublist(start, start + unit);
      final body = <Instruction>[];
      var i = 0;
      while (i < steps.length) {
        if (same(procedure, i)) {
          body.add(const Call());
          i += unit;
        } else if (steps.length - i < unit &&
            List.generate(
              steps.length - i,
              (j) => steps[i + j].kind == procedure[j].kind,
            ).every((s) => s)) {
          // The run stops on the goal, so a final call may end part-way.
          body.add(const Call());
          i = steps.length;
        } else {
          body.add(steps[i++]);
        }
      }
      final program = Program(body, procedure: procedure);
      if (program.blockCount <= maxBlocks) return program;
    }
  }
  return null;
}

/// Saves each corridor length once and reuses it until the route needs a
/// different distance. Used to verify variables lessons in both editors.
Program withSavedSteps(List<Instruction> steps) {
  final commands = <Instruction>[];
  int? stored;
  for (var i = 0; i < steps.length;) {
    if (steps[i] is! Move) {
      commands.add(steps[i++]);
      continue;
    }
    var count = 0;
    while (i < steps.length && steps[i] is Move) {
      count += (steps[i++] as Move).steps;
    }
    if (count != stored) commands.add(SetSteps(count));
    stored = count;
    commands.add(const MoveSteps());
  }
  return Program(commands);
}

void main() {
  test('each pack holds only its own concept', () {
    for (final pack in levelPacks) {
      final levels = parseLevelPack(
        File('assets/levels/$pack.json').readAsStringSync(),
      );
      expect(levels.map((l) => l.concept).toSet(), {pack});
    }
  });

  final levels = <Level>[
    for (final pack in levelPacks)
      ...parseLevelPack(File('assets/levels/$pack.json').readAsStringSync()),
  ];

  test('level ids are unique', () {
    final ids = levels.map((l) => l.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  for (final level in levels) {
    if (level.concept == 'variables') {
      test('${level.id} teaches saving and using a value', () {
        final answer = withSavedSteps(solve(level)!.body);
        expect(answer.body, contains(isA<SetSteps>()));
        expect(answer.body, contains(isA<MoveSteps>()));
        expect(validateProgram(answer, level), isEmpty);
        expect(runProgram(answer, level).succeeded, isTrue);
      });
    }
    if (level.concept == 'conditions') {
      test('${level.id} teaches checked steps with its own palette', () {
        final steps = solve(level)!.body;
        final checked = <Instruction>[];
        // Exercise a blocked check at the start of the introductory lesson.
        if (!level.isOpen(level.start.step(level.startFacing))) {
          checked.add(const IfPathClear([Move()]));
        }
        for (var i = 0; i < steps.length;) {
          if (steps[i] is! Move) {
            checked.add(steps[i++]);
            continue;
          }
          final start = i;
          while (i < steps.length && steps[i] is Move) {
            i++;
          }
          if (level.palette.contains(InstructionKind.repeat)) {
            checked.add(
              const Repeat(9, [
                IfPathClear([Move()]),
              ]),
            );
          } else {
            checked.addAll([
              for (var j = start; j < i; j++) const IfPathClear([Move()]),
            ]);
          }
        }
        final solution = Program(checked);
        expect(validateProgram(solution, level), isEmpty);
        final run = runProgram(solution, level);
        expect(run.succeeded, isTrue);
        expect(run.events.whereType<PathChecked>().any((e) => e.clear), isTrue);
        expect(
          run.events.whereType<PathChecked>().any((e) => !e.clear),
          isTrue,
        );
      });
    }
    test('${level.id} is solvable with its palette and block limit', () {
      final straight = solve(level);
      expect(straight, isNotNull, reason: 'no route to the goal');
      final max = level.maxBlocks;
      final calls = level.palette.contains(InstructionKind.call);
      final solution = level.concept == 'variables'
          ? withSavedSteps(straight!.body)
          : max == null || straight!.blockCount <= max
          ? straight!
          : calls
          ? withOneProcedure(straight.body, max)
          : withOneRepeat(straight.body, max);
      expect(solution, isNotNull, reason: 'no answer fits $max blocks');
      expect(validateProgram(solution!, level), isEmpty);
      expect(runProgram(solution, level).succeeded, isTrue);
    });
  }
}
