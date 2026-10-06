import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/tutorial/data/tutorial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tutorials = parseTutorials(
    File('assets/config/tutorials.json').readAsStringSync(),
  );
  final concepts = [
    for (final c
        in (jsonDecode(File('assets/config/skills.json').readAsStringSync())
                as Map)['concepts']
            as List)
      (c as Map)['id'] as String,
  ];

  test('every island has a demo', () {
    expect(tutorials.keys.toSet(), concepts.toSet());
    for (final MapEntry(:key, :value) in tutorials.entries) {
      expect(value.concept, key);
    }
  });

  for (final tutorial in tutorials.values) {
    test('the ${tutorial.concept} demo ends with the puzzle solved', () {
      final level = tutorial.level;
      final blocks = BlocksCubit(
        maxBlocks: level.maxBlocks,
        start: level.starter,
      );
      addTearDown(blocks.close);
      final runs = <bool>[];
      for (final action in tutorial.actions) {
        final before = blocks.state;
        applyTutorialAction(blocks, action);
        if (action is PressGo) {
          expect(validateProgram(blocks.program, level), isEmpty);
          runs.add(runProgram(blocks.program, level).succeeded);
        } else if (action is! PickBlock) {
          // Every other step visibly changes the blocks.
          expect(
            identical(blocks.state.main, before.main) &&
                identical(blocks.state.star, before.star),
            isFalse,
            reason: '$action did nothing',
          );
        }
      }
      expect(runs.last, isTrue, reason: 'the demo must end solved');
      // Only Fix it! shows a run that goes off course first.
      if (tutorial.concept == 'debugging') {
        expect(runs, [false, true]);
      } else {
        expect(runs, [true]);
      }
    });
  }
}
