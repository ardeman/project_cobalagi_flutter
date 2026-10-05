import 'dart:io';

import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
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
    test('${level.id} is solvable with its palette and block limit', () {
      final straight = solve(level);
      expect(straight, isNotNull, reason: 'no route to the goal');
      final max = level.maxBlocks;
      final solution = max == null || straight!.blockCount <= max
          ? straight!
          : withOneRepeat(straight.body, max);
      expect(solution, isNotNull, reason: 'no loop answer fits $max blocks');
      expect(validateProgram(solution!, level), isEmpty);
      expect(runProgram(solution, level).succeeded, isTrue);
    });
  }
}
