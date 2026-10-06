import 'dart:convert';
import 'dart:io';

import '../../play/level_assets_test.dart'
    show withOneRepeat, withOneProcedure, withSavedSteps, withUntilGoal;

import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/editors/typed/cubit/typed_code_cubit.dart';
import 'package:cobalagi/features/editors/typed/data/typed_program.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('variable syntax keeps IDs, validates ordering and round-trips', () {
    const source = 'steps = 3;\nmove(steps);\nsteps = 2;\nmove(steps);';
    final program = compileCode(source);
    expect((program.body.first as SetSteps).value, 3);
    expect(program.body[1], isA<MoveSteps>());
    expect(codeLine(source, program.body[2].blockId), 3);
    final roundTrip = compileCode(formatCode(program));
    expect(roundTrip.blockCount, 4);
    expect((roundTrip.body[2] as SetSteps).value, 2);
    for (final invalid in [
      'steps = 0;',
      'steps = 10;',
      'steps = two;',
      'steps 3;',
      'move(other);',
    ]) {
      expect(() => compileCode(invalid), throwsA(isA<CodeIssue>()));
    }
  });

  test(
    'compiles nested checks, repeats and a procedure to shared instructions',
    () {
      const source = '''// Our staircase
 define star {
   move(); turn_right();
 }
 repeat(2) {
   if_path_clear { star(); }
 }
 turn_left();
''';
      final program = compileCode(source);
      expect(program.procedure.first, isA<Move>());
      expect(program.procedure.last, isA<TurnRight>());
      final repeat = program.body.first as Repeat;
      expect(repeat.times, 2);
      expect((repeat.body.single as IfPathClear).body.single, isA<Call>());
      expect(program.body.last, isA<TurnLeft>());
      expect(program.blockCount, 6);
      expect(codeLine(source, repeat.blockId), 5);
      expect(
        program.procedure.first.blockId,
        isNot(program.procedure.last.blockId),
      );
      expect(codeLine(source, program.procedure.last.blockId), 3);
    },
  );

  for (final source in [
    'move()',
    'move(3);',
    'Move();',
    'repeat(2) { move();',
    'move(); }',
    'if_path_clear { } ;',
    'move(); @',
  ]) {
    test('rejects malformed source: $source', () {
      expect(() => compileCode(source), throwsA(isA<CodeIssue>()));
    });
  }
  test(
    'reports source line and repeat range without throwing unrelated exceptions',
    () {
      for (final count in [
        '0',
        '10',
        '999999999999999999999999999',
        'two',
        '-1',
      ]) {
        expect(
          () => compileCode('\nrepeat($count) { move(); }'),
          throwsA(isA<CodeIssue>().having((e) => e.line, 'line', 2)),
        );
      }
      expect(
        () => compileCode('define star {}\ndefine star {}'),
        throwsA(
          isA<CodeIssue>().having(
            (e) => e.problem,
            'problem',
            CodeProblem.duplicateStar,
          ),
        ),
      );
      expect(
        () => compileCode('repeat(2) { define star {} }'),
        throwsA(
          isA<CodeIssue>().having(
            (e) => e.problem,
            'problem',
            CodeProblem.nestedStar,
          ),
        ),
      );
    },
  );
  test('bounds parser length and nesting', () {
    expect(() => compileCode(' ' * 8001), throwsA(isA<CodeIssue>()));
    expect(
      () => compileCode('${'repeat(2) {' * 17}move();${'}' * 17}'),
      throwsA(
        isA<CodeIssue>().having(
          (e) => e.problem,
          'problem',
          CodeProblem.tooLarge,
        ),
      ),
    );
    expect(compileCode('// nothing\n').body, isEmpty);
  });

  test(
    'every handmade lesson solution works through code and the shared interpreter',
    () {
      for (final file in Directory(
        'assets/levels',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
        final levels =
            (jsonDecode(file.readAsStringSync()) as Map)['levels'] as List;
        for (final json in levels) {
          final level = Level.fromJson((json as Map).cast<String, Object?>());
          final straight = solve(level)!;
          final max = level.maxBlocks;
          final solution = level.concept == 'variables'
              ? withSavedSteps(straight.body)
              : max == null || straight.blockCount <= max
              ? straight
              : level.palette.contains(InstructionKind.call)
              ? withOneProcedure(straight.body, max)!
              : level.palette.contains(InstructionKind.untilGoal)
              ? withUntilGoal(straight.body, max)!
              : withOneRepeat(straight.body, max)!;
          final code = compileCode(formatCode(solution));
          expect(validateProgram(code, level), isEmpty, reason: level.id);
          expect(runProgram(code, level).succeeded, isTrue, reason: level.id);
        }
      }
    },
  );

  final level = Level.fromRows(
    id: 'test',
    concept: 'sequencing',
    rows: ['S.G'],
    startFacing: Direction.east,
    palette: {InstructionKind.move},
    maxBlocks: 2,
  );
  test(
    'typed cubit rejects palette and block-limit bypasses and recovers after edits',
    () async {
      final cubit = TypedCodeCubit(level);
      addTearDown(cubit.close);
      cubit.edit('turn_left();');
      expect(cubit.state.canRun, isFalse);
      expect(cubit.state.issues.single, isA<DisallowedInstruction>());
      cubit.edit('move(); move(); move();');
      expect(cubit.state.issues.single, isA<TooManyBlocks>());
      cubit.edit('move()');
      expect(cubit.state.program, isNull);
      cubit.edit('move();\nmove();');
      expect(cubit.state.canRun, isTrue);
      expect(runProgram(cubit.state.program!, level).succeeded, isTrue);
      cubit.edit('');
      expect(cubit.state.canRun, isFalse);
    },
  );

  test('shared validation catches empty containers and self calls', () {
    final all = Level.fromRows(
      id: 'all',
      concept: 'functions',
      rows: ['SG'],
      startFacing: Direction.east,
      palette: InstructionKind.values.toSet(),
    );
    expect(
      validateProgram(compileCode('repeat(2) {}'), all).single,
      isA<EmptyRepeat>(),
    );
    expect(
      validateProgram(compileCode('if_path_clear {}'), all).single,
      isA<EmptyCondition>(),
    );
    expect(
      validateProgram(compileCode('star();'), all).single,
      isA<EmptyProcedure>(),
    );
    expect(
      validateProgram(
        compileCode('define star { star(); } star();'),
        all,
      ).single,
      isA<CallInProcedure>(),
    );
  });
}
