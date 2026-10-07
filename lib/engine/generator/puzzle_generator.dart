import 'dart:math';

import '../interpreter/interpreter.dart';
import '../program/instruction.dart';
import '../program/program.dart';
import '../program/program_json.dart';
import '../world/direction.dart';
import '../world/grid_point.dart';
import '../world/level.dart';
import 'solver.dart';

/// Puzzle families the generator can produce, one per early skill-map concept.
enum PuzzleKind {
  directions,
  sequencing,
  loops,
  functions,
  conditions,
  variables,
  debugging,
  until,
  otherwise,
}

const minDifficulty = 1;
const maxDifficulty = 5;

final class GeneratedPuzzle {
  const GeneratedPuzzle(this.level, this.solution);

  final Level level;

  /// The intended answer, in the style the concept teaches.
  final Program solution;
}

/// Creates a fresh, verified puzzle. The same [kind], [difficulty] and [seed]
/// always give the same puzzle; change the seed for a new variation.
///
/// Puzzles are a one-cell-wide path through walls, so the intended route is the
/// only route.
GeneratedPuzzle generatePuzzle(
  PuzzleKind kind, {
  required int difficulty,
  required int seed,
}) {
  RangeError.checkValueInInterval(
    difficulty,
    minDifficulty,
    maxDifficulty,
    'difficulty',
  );
  final random = Random(seed);
  if (kind == PuzzleKind.variables) return _variables(random, difficulty, seed);
  if (kind == PuzzleKind.debugging) {
    return _debugging(random, difficulty, seed);
  }
  if (kind == PuzzleKind.until) return _until(random, difficulty, seed);
  if (kind == PuzzleKind.otherwise) {
    return _otherwise(random, difficulty, seed);
  }
  if (kind == PuzzleKind.conditions) {
    return _conditions(random, difficulty, seed);
  }
  for (var attempt = 0; attempt < 200; attempt++) {
    final solution = switch (kind) {
      PuzzleKind.directions => _directions(random, difficulty),
      PuzzleKind.sequencing => _sequencing(random, difficulty),
      PuzzleKind.loops => _loops(random, difficulty),
      PuzzleKind.functions => _functions(random, difficulty),
      PuzzleKind.variables => throw StateError('variables use a stored value'),
      PuzzleKind.conditions => throw StateError(
        'conditions use a checked route',
      ),
      PuzzleKind.debugging => throw StateError('debugging plants a bug'),
      PuzzleKind.until => throw StateError('until traces a counted route'),
      PuzzleKind.otherwise => throw StateError('otherwise follows the walls'),
    };
    final puzzle = _buildPuzzle(
      kind,
      solution,
      Direction.values[random.nextInt(4)],
      id: '${kind.name}-d$difficulty-s$seed',
      difficulty: difficulty,
    );
    if (puzzle != null) return puzzle;
  }
  throw StateError('no valid ${kind.name} puzzle for seed $seed');
}

const _sequencePalette = {
  InstructionKind.move,
  InstructionKind.turnLeft,
  InstructionKind.turnRight,
};

const _loopPalette = {..._sequencePalette, InstructionKind.repeat};

const _functionPalette = {..._sequencePalette, InstructionKind.call};

const _variablePalette = {
  InstructionKind.setSteps,
  InstructionKind.moveSteps,
  InstructionKind.turnLeft,
  InstructionKind.turnRight,
};

/// Reuse one stored distance on early routes; later routes need new values.
GeneratedPuzzle _variables(Random random, int difficulty, int seed) {
  for (var attempt = 0; attempt < 200; attempt++) {
    final route = <Instruction>[];
    final commands = <Instruction>[];
    var stored = 0;
    final first = 2 + random.nextInt(3);
    for (var segment = 0; segment < difficulty + 1; segment++) {
      if (segment > 0) {
        final turn = _turn(random);
        route.add(turn);
        commands.add(turn);
      }
      final count = difficulty < 3 || segment.isEven
          ? first
          : (first == 4 ? 2 : first + 1);
      route.addAll(_moves(count));
      if (stored != count) commands.add(SetSteps(count));
      stored = count;
      commands.add(const MoveSteps());
    }
    final puzzle = _buildPuzzle(
      PuzzleKind.variables,
      Program(route),
      Direction.values[random.nextInt(4)],
      id: 'variables-d$difficulty-s$seed',
      difficulty: difficulty,
    );
    if (puzzle == null) continue;
    final solution = Program(commands);
    final level = Level.fromJson({
      ...puzzle.level.toJson(),
      'maxBlocks': solution.blockCount,
    });
    if (runProgram(solution, level).succeeded) {
      return GeneratedPuzzle(level, solution);
    }
  }
  throw StateError('no valid variables puzzle for seed $seed');
}

const _untilPalette = {..._sequencePalette, InstructionKind.untilGoal};

/// A shape that repeats an unknown number of times, all the way to the
/// flag: a corridor, then stairs and zigzags, later after a lead-in. The
/// route is laid out with a counted repeat, but the answer is a
/// repeat-until, and the block limit leaves no room to write it out.
GeneratedPuzzle _until(Random random, int difficulty, int seed) {
  for (var attempt = 0; attempt < 200; attempt++) {
    final turn = _turn(random);
    final back = turn is TurnLeft ? const TurnRight() : const TurnLeft();
    final unit = switch (difficulty) {
      1 => [const Move()],
      2 => [const Move(), turn, const Move(), back],
      _ => [
        ..._moves(1 + random.nextInt(2)),
        turn,
        ..._moves(1 + random.nextInt(2)),
        back,
      ],
    };
    final lead = [
      if (difficulty >= 4) ...[..._moves(1 + random.nextInt(2)), _turn(random)],
    ];
    final times = (difficulty == 1 ? 4 : 3) + random.nextInt(4);
    final puzzle = _buildPuzzle(
      PuzzleKind.until,
      Program([...lead, Repeat(times, unit)]),
      Direction.values[random.nextInt(4)],
      id: 'until-d$difficulty-s$seed',
      difficulty: difficulty,
    );
    if (puzzle == null) continue;
    final solution = Program([...lead, RepeatUntilGoal(unit)]);
    final level = Level.fromJson({
      ...puzzle.level.toJson(),
      'maxBlocks': solution.blockCount + 1,
    });
    if (!runProgram(solution, level).succeeded) continue;
    // Writing every step out must not fit.
    if (solve(level)!.blockCount <= level.maxBlocks!) continue;
    return GeneratedPuzzle(level, solution);
  }
  throw StateError('no valid until puzzle for seed $seed');
}

const _otherwisePalette = {..._untilPalette, InstructionKind.ifElse};

/// A winding corridor that always turns the same way, with straights of
/// different lengths, so no counted repeat fits. The answer follows the
/// walls: repeat until the flag, step if the path is clear, otherwise turn.
/// Harder ones have more straights.
GeneratedPuzzle _otherwise(Random random, int difficulty, int seed) {
  for (var attempt = 0; attempt < 400; attempt++) {
    final turn = _turn(random);
    final segments = difficulty + 1;
    // Growing straights wind outwards instead of into themselves.
    // Fewer straights get a wider range, so layouts still vary.
    final spread = difficulty == 1 ? 4 : 2;
    var length = 1 + random.nextInt(spread);
    final route = <Instruction>[];
    for (var s = 0; s < segments; s++) {
      if (s > 0) {
        route.add(turn);
        length = difficulty == 1
            ? 1 + random.nextInt(spread)
            : length + random.nextInt(2) + (s.isEven ? 1 : 0);
      }
      route.addAll(_moves(length));
    }
    final puzzle = _buildPuzzle(
      PuzzleKind.otherwise,
      Program(route),
      Direction.values[random.nextInt(4)],
      id: 'otherwise-d$difficulty-s$seed',
      difficulty: difficulty,
    );
    if (puzzle == null) continue;
    final solution = Program([
      RepeatUntilGoal([
        IfElsePathClear([const Move()], [turn]),
      ]),
    ]);
    final level = Level.fromJson({
      ...puzzle.level.toJson(),
      'maxBlocks': solution.blockCount + 1,
    });
    if (!runProgram(solution, level).succeeded) continue;
    // Writing every step out must not fit.
    if (solve(level)!.blockCount <= level.maxBlocks!) continue;
    return GeneratedPuzzle(level, solution);
  }
  throw StateError('no valid otherwise puzzle for seed $seed');
}

/// A working program with one bug planted in it, for the child to find and
/// fix: steps and turns at first, then a route with a repeat. The block
/// limit leaves room for the fix but not for writing a different program.
GeneratedPuzzle _debugging(Random random, int difficulty, int seed) {
  final base = difficulty <= 2 ? PuzzleKind.sequencing : PuzzleKind.loops;
  final baseDifficulty = difficulty <= 2 ? difficulty + 1 : difficulty - 2;
  for (var attempt = 0; attempt < 200; attempt++) {
    final puzzle = generatePuzzle(
      base,
      difficulty: baseDifficulty,
      seed: seed * 1000 + attempt,
    );
    final starter = plantBug(puzzle.solution, random);
    if (starter == null) continue;
    final level = Level.fromJson({
      ...puzzle.level.toJson(),
      'id': 'debugging-d$difficulty-s$seed',
      'concept': PuzzleKind.debugging.name,
      'maxBlocks': max(puzzle.solution.blockCount, starter.blockCount),
      'starter': programToJson(starter),
    });
    if (!runProgram(starter, level).succeeded &&
        runProgram(puzzle.solution, level).succeeded) {
      return GeneratedPuzzle(level, puzzle.solution);
    }
  }
  throw StateError('no valid debugging puzzle for seed $seed');
}

/// [program] with one bug: a turn the wrong way, a step missing or one too
/// many, or a repeat count off by one. Null when it has nowhere to put one.
Program? plantBug(Program program, Random random) {
  // Every place a bug can go: a path of indexes into nested bodies.
  final sites = <(String, List<int>)>[];
  void scan(List<Instruction> body, List<int> at) {
    final moves = body.whereType<Move>().length;
    for (var i = 0; i < body.length; i++) {
      final here = [...at, i];
      switch (body[i]) {
        case TurnLeft() || TurnRight():
          sites.add(('flip', here));
        case Move():
          sites.add(('extra', here));
          if (moves > 1) sites.add(('drop', here));
        case Repeat(:final times, :final body):
          sites.add(('more', here));
          if (times > 2) sites.add(('fewer', here));
          scan(body, here);
        default:
          break;
      }
    }
  }

  scan(program.body, const []);
  if (sites.isEmpty) return null;
  final (bug, path) = sites[random.nextInt(sites.length)];

  List<Instruction> change(List<Instruction> body, int depth) {
    final i = path[depth];
    final out = [...body];
    if (depth < path.length - 1) {
      final repeat = body[i] as Repeat;
      out[i] = Repeat(repeat.times, change(repeat.body, depth + 1));
      return out;
    }
    switch (bug) {
      case 'flip':
        out[i] = body[i] is TurnLeft ? const TurnRight() : const TurnLeft();
      case 'extra':
        out.insert(i, const Move());
      case 'drop':
        out.removeAt(i);
      case 'more' || 'fewer':
        final repeat = body[i] as Repeat;
        out[i] = Repeat(repeat.times + (bug == 'more' ? 1 : -1), repeat.body);
    }
    return out;
  }

  return Program(change(program.body, 0), procedure: program.procedure);
}

const _conditionPalette = {..._loopPalette, InstructionKind.ifPathClear};

/// Variable-length corridors: repeat a checked step, stop safely at each
/// wall, then turn. Both clear and blocked checks occur before the goal.
GeneratedPuzzle _conditions(Random random, int difficulty, int seed) {
  for (var attempt = 0; attempt < 200; attempt++) {
    final route = <Instruction>[];
    final checked = <Instruction>[];
    for (var segment = 0; segment < difficulty + 1; segment++) {
      if (segment > 0) {
        final turn = _turn(random);
        route.add(turn);
        checked.add(turn);
      }
      route.addAll(_moves(2 + random.nextInt(4)));
      checked.add(
        const Repeat(6, [
          IfPathClear([Move()]),
        ]),
      );
    }
    final puzzle = _buildPuzzle(
      PuzzleKind.conditions,
      Program(route),
      Direction.values[random.nextInt(4)],
      id: 'conditions-d$difficulty-s$seed',
      difficulty: difficulty,
    );
    if (puzzle == null) continue;
    final solution = Program(checked);
    if (runProgram(solution, puzzle.level).succeeded) {
      return GeneratedPuzzle(puzzle.level, solution);
    }
  }
  throw StateError('no valid conditions puzzle for seed $seed');
}

Instruction _turn(Random random) =>
    random.nextBool() ? const TurnLeft() : const TurnRight();

List<Instruction> _moves(int count) => [
  for (var i = 0; i < count; i++) const Move(),
];

/// Short paths with one or two turns: "which way is left?"
Program _directions(Random random, int difficulty) {
  final turns = difficulty < 3 ? 1 : 2;
  return Program([
    ..._moves(1 + random.nextInt(2)),
    for (var t = 0; t < turns; t++) ...[
      _turn(random),
      ..._moves(1 + random.nextInt(2)),
    ],
  ]);
}

/// Longer paths with more turns; from difficulty 3 the actor may need to turn
/// before the first step.
Program _sequencing(Random random, int difficulty) {
  final segments = difficulty + 1;
  return Program([
    if (difficulty >= 3 && random.nextBool()) _turn(random),
    for (var s = 0; s < segments; s++) ...[
      if (s > 0) _turn(random),
      ..._moves(1 + random.nextInt(3)),
    ],
  ]);
}

/// A repeated pattern, optionally with a lead-in. The block limit only fits
/// the loop solution, so writing every step out is not enough.
Program _loops(Random random, int difficulty) {
  final unit = switch (difficulty) {
    1 => [const Move()],
    2 => [const Move(), _turn(random), const Move(), _turn(random)],
    _ => [
      ..._moves(1 + random.nextInt(2)),
      _turn(random),
      ..._moves(1 + random.nextInt(2)),
      _turn(random),
    ],
  };
  final times = difficulty == 1 ? 4 + random.nextInt(4) : 3 + random.nextInt(2);
  return Program([
    if (difficulty >= 4) ...[..._moves(1 + random.nextInt(2)), _turn(random)],
    Repeat(times, unit),
    // The unit already ends with a turn, so the finish is straight moves.
    if (difficulty >= 5) ..._moves(1 + random.nextInt(2)),
  ]);
}

/// A shape that comes back several times, like stairs. The block limit only
/// fits building the shape once in the star block and calling it; from
/// difficulty 3 the calls come with a lead-in and moves in between, so a plain
/// loop wouldn't do either.
Program _functions(Random random, int difficulty) {
  final turn = _turn(random);
  final back = turn is TurnLeft ? const TurnRight() : const TurnLeft();
  final unit = <Instruction>[
    ..._moves(difficulty == 1 ? 1 : 1 + random.nextInt(2)),
    turn,
    ..._moves(1 + random.nextInt(2)),
    back,
  ];
  final calls = 3 + random.nextInt(2);
  return Program([
    if (difficulty >= 3) ..._moves(1 + random.nextInt(2)),
    for (var c = 0; c < calls; c++) ...[
      if (c > 0 && difficulty >= 4) ..._moves(1 + random.nextInt(2)),
      const Call(),
    ],
  ], procedure: unit);
}

GeneratedPuzzle? _buildPuzzle(
  PuzzleKind kind,
  Program solution,
  Direction facing, {
  required String id,
  required int difficulty,
}) {
  // Walk the intended solution to trace the path.
  final path = <GridPoint>[const GridPoint(0, 0)];
  var heading = facing;
  void walk(List<Instruction> body) {
    for (final instruction in body) {
      switch (instruction) {
        case Move(:final steps):
          for (var i = 0; i < steps; i++) {
            path.add(path.last.step(heading));
          }
        case TurnLeft():
          heading = heading.left;
        case TurnRight():
          heading = heading.right;
        case Repeat(:final times, :final body):
          for (var i = 0; i < times; i++) {
            walk(body);
          }
        case Call():
          walk(solution.procedure);
        case SetSteps() || MoveSteps():
          throw StateError('trace the route before adding variables');
        case IfPathClear() || IfElsePathClear():
          throw StateError('trace the route before adding path checks');
        case RepeatUntilGoal():
          throw StateError('trace the route with a counted repeat');
      }
    }
  }

  walk(solution.body);
  if (!_isSimplePath(path)) return null;

  // Shift into a grid with a one-tile wall border.
  final minX = path.map((p) => p.x).reduce(min);
  final minY = path.map((p) => p.y).reduce(min);
  final cells = {
    for (final p in path) GridPoint(p.x - minX + 1, p.y - minY + 1),
  };
  final width = cells.map((p) => p.x).reduce(max) + 2;
  final height = cells.map((p) => p.y).reduce(max) + 2;
  final shift = GridPoint(1 - minX, 1 - minY);
  GridPoint shifted(GridPoint p) => GridPoint(p.x + shift.x, p.y + shift.y);

  final palette = switch (kind) {
    PuzzleKind.loops => _loopPalette,
    PuzzleKind.functions => _functionPalette,
    PuzzleKind.conditions => _conditionPalette,
    PuzzleKind.variables => _variablePalette,
    PuzzleKind.until => _untilPalette,
    PuzzleKind.otherwise => _otherwisePalette,
    PuzzleKind.directions ||
    PuzzleKind.sequencing ||
    PuzzleKind.debugging => _sequencePalette,
  };
  final limited = kind == PuzzleKind.loops || kind == PuzzleKind.functions;
  final level = Level(
    id: id,
    concept: kind.name,
    tiles: [
      for (var y = 0; y < height; y++)
        [
          for (var x = 0; x < width; x++)
            cells.contains(GridPoint(x, y)) ? Tile.floor : Tile.wall,
        ],
    ],
    start: shifted(path.first),
    startFacing: facing,
    goal: shifted(path.last),
    palette: palette,
    maxBlocks: limited ? solution.blockCount + 1 : null,
  );

  // Verify: the intended solution works and there is no shorter route. The
  // run stops on the goal, so a loop's trailing turn doesn't count.
  final run = runProgram(solution, level);
  if (!run.succeeded) return null;
  final shortest = solve(level);
  if (shortest == null || shortest.body.length != run.steps) return null;
  // A loop or star puzzle must not fit within the block limit without one.
  if (limited && shortest.blockCount <= level.maxBlocks!) return null;
  return GeneratedPuzzle(level, solution);
}

/// No cell is visited twice and the path never runs alongside itself, so the
/// walls leave exactly one route.
bool _isSimplePath(List<GridPoint> path) {
  final index = <GridPoint, int>{};
  for (var i = 0; i < path.length; i++) {
    if (index.containsKey(path[i])) return false;
    index[path[i]] = i;
  }
  for (var i = 0; i < path.length; i++) {
    for (final d in Direction.values) {
      final j = index[path[i].step(d)];
      if (j != null && (j - i).abs() != 1) return false;
    }
  }
  return true;
}
