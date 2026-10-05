import 'dart:io';

import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/play/data/level_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final levels = <Level>[
    for (final pack in levelPacks)
      ...parseLevelPack(File('assets/levels/$pack.json').readAsStringSync()),
  ];

  test('level ids are unique', () {
    final ids = levels.map((l) => l.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  for (final level in levels) {
    test('${level.id} is solvable with its palette', () {
      final solution = solve(level);
      expect(solution, isNotNull, reason: 'no route to the goal');
      expect(validateProgram(solution!, level), isEmpty);
      expect(runProgram(solution, level).succeeded, isTrue);
    });
  }
}
