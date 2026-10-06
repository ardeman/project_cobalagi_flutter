import '../world/level.dart';
import 'instruction.dart';
import 'program.dart';

/// Reads a program written in lesson JSON, such as a debugging lesson's
/// starter blocks.
///
/// Either a list of instructions (the main row), or
/// `{"body": [...], "procedure": [...]}` when the star row is used too.
/// An instruction is `"move"`, `"turnLeft"`, `"turnRight"`, `"call"`,
/// `"moveSteps"`, `{"repeat": 3, "body": [...]}`, `{"setSteps": 2}` or
/// `{"ifPathClear": [...]}` or `{"untilGoal": [...]}`.
Program programFromJson(Object? json) => switch (json) {
  List<Object?> body => Program(_list(body)),
  {'body': final List<Object?> body, 'procedure': final List<Object?> star} =>
    Program(_list(body), procedure: _list(star)),
  {'body': final List<Object?> body} => Program(_list(body)),
  _ => throw LevelFormatException('invalid program: $json'),
};

List<Instruction> _list(List<Object?> items) => [
  for (final item in items) _instruction(item),
];

Instruction _instruction(Object? json) => switch (json) {
  'move' => const Move(),
  'turnLeft' => const TurnLeft(),
  'turnRight' => const TurnRight(),
  'call' => const Call(),
  'moveSteps' => const MoveSteps(),
  {'repeat': final int times, 'body': final List<Object?> body} => Repeat(
    times,
    _list(body),
  ),
  {'setSteps': final int value} => SetSteps(value),
  {'ifPathClear': final List<Object?> body} => IfPathClear(_list(body)),
  {'untilGoal': final List<Object?> body} => RepeatUntilGoal(_list(body)),
  _ => throw LevelFormatException('invalid instruction: $json'),
};

/// The inverse of [programFromJson]. One-step moves only, as blocks make.
Object programToJson(Program program) => program.procedure.isEmpty
    ? _listToJson(program.body)
    : {
        'body': _listToJson(program.body),
        'procedure': _listToJson(program.procedure),
      };

List<Object> _listToJson(List<Instruction> list) => [
  for (final instruction in list)
    switch (instruction) {
      Move(:final steps) when steps == 1 => 'move',
      Move() => throw ArgumentError('multi-step moves have no block'),
      TurnLeft() => 'turnLeft',
      TurnRight() => 'turnRight',
      Call() => 'call',
      MoveSteps() => 'moveSteps',
      Repeat(:final times, :final body) => {
        'repeat': times,
        'body': _listToJson(body),
      },
      SetSteps(:final value) => {'setSteps': value},
      IfPathClear(:final body) => {'ifPathClear': _listToJson(body)},
      RepeatUntilGoal(:final body) => {'untilGoal': _listToJson(body)},
    },
];
