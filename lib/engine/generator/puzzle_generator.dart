import 'dart:math';

import '../interpreter/interpreter.dart';
import '../program/instruction.dart';
import '../program/program.dart';
import '../world/direction.dart';
import '../world/grid_point.dart';
import '../world/level.dart';
import 'solver.dart';

/// Puzzle families the generator can produce, one per early skill-map concept.
enum PuzzleKind { directions, sequencing, loops, functions, conditions }

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
  if (kind == PuzzleKind.conditions) {
    return _conditions(random, difficulty, seed);
  }
  for (var attempt = 0; attempt < 200; attempt++) {
    final solution = switch (kind) {
      PuzzleKind.directions => _directions(random, difficulty),
      PuzzleKind.sequencing => _sequencing(random, difficulty),
      PuzzleKind.loops => _loops(random, difficulty),
      PuzzleKind.functions => _functions(random, difficulty),
      PuzzleKind.conditions => throw StateError(
        'conditions use a checked route',
      ),
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
        case IfPathClear():
          throw StateError('trace the route before adding path checks');
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
    PuzzleKind.directions || PuzzleKind.sequencing => _sequencePalette,
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
