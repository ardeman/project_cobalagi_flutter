import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/play/cubit/play_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final level = Level.fromRows(
  id: 't',
  concept: 'sequencing',
  rows: ['S..G'],
  startFacing: Direction.east,
  palette: {InstructionKind.move, InstructionKind.turnLeft},
);

const solved = Program([
  Move(blockId: 'a'),
  Move(blockId: 'b'),
  Move(blockId: 'c'),
]);

/// Plays events like the world view does, until the run pauses or ends.
void playOut(PlayCubit cubit) {
  while (cubit.state.currentEvent != null) {
    cubit.eventShown();
  }
}

void main() {
  test('a run plays every event, highlights blocks and succeeds', () {
    final cubit = PlayCubit(level)..run(solved);
    expect(cubit.state.phase, PlayPhase.running);
    expect(cubit.state.activeBlockId, 'a');
    cubit.eventShown();
    expect(cubit.state.activeBlockId, 'b');
    playOut(cubit);
    expect(cubit.state.phase, PlayPhase.succeeded);
    expect(cubit.state.runs, 1);
  });

  test('a failing run ends in failed with the outcome', () {
    final cubit = PlayCubit(level)..run(const Program([Move()]));
    playOut(cubit);
    expect(cubit.state.phase, PlayPhase.failed);
    expect(cubit.state.result!.outcome, RunOutcome.stoppedShort);
  });

  test('step mode pauses after each event; run continues without pauses', () {
    final cubit = PlayCubit(level)..step(solved);
    cubit.eventShown();
    expect(cubit.state.playing, isFalse);
    expect(cubit.state.currentEvent, isNull);
    cubit.step(solved);
    expect(cubit.state.currentEvent, isA<Moved>());
    cubit.run(solved);
    playOut(cubit);
    expect(cubit.state.phase, PlayPhase.succeeded);
  });

  test('invalid programs report issues and do not run', () {
    final cubit = PlayCubit(level)
      ..run(const Program([TurnRight(blockId: 'x')]));
    expect(cubit.state.phase, PlayPhase.editing);
    expect(cubit.state.issues.single, isA<DisallowedInstruction>());
    expect(cubit.state.issues.single.blockId, 'x');
  });

  test('reset returns to editing and keeps the run count', () {
    final cubit = PlayCubit(level)..run(solved);
    playOut(cubit);
    cubit.reset();
    expect(cubit.state.phase, PlayPhase.editing);
    expect(cubit.state.result, isNull);
    expect(cubit.state.runs, 1);
  });

  test('late callbacks after a reset are ignored', () {
    final cubit = PlayCubit(level)..run(solved);
    cubit
      ..reset()
      ..eventShown();
    expect(cubit.state.phase, PlayPhase.editing);
  });
}
