import '../interpreter/interpreter.dart';
import '../program/instruction.dart';
import '../program/program.dart';
import '../world/direction.dart';
import '../world/grid_point.dart';
import '../world/level.dart';
import 'solver.dart';

/// Every block in [program] that takes the robot no closer to the finish
/// (with every star) at some point in its run: a turn the wrong way, a move
/// away, a walk into a rock. In the order they first go wrong; empty when
/// every step is right, so the program only needs more blocks.
///
/// Each step is judged from where a right program would be: a wrong step is
/// skipped and the run goes on, so one mistake doesn't make every later
/// block look wrong. Every step of some shortest answer brings the finish
/// one step nearer, so any right answer passes, not just one.
///
/// Used by the hint to show the child which of their blocks to change.
List<String> offTrackBlocks(Level level, Program program) {
  final known = <String, int?>{};
  int? left(GridPoint at, Direction facing, Set<GridPoint> collected) {
    final stars = {...collected, if (level.stars.contains(at)) at};
    final key = '$at $facing ${[for (final s in stars) '$s']..sort()}';
    return known.putIfAbsent(
      key,
      () => stepsToFinish(level, at, facing, stars),
    );
  }

  final wrong = <String>[];
  runProgram(
    program,
    level,
    check: (at, facing, collected, next, nextFacing, blockId) {
      final before = left(at, facing, collected);
      bool closer(GridPoint to, Direction toFacing) {
        final after = left(to, toFacing, collected);
        return before != null && after != null && after < before;
      }

      if (closer(next, nextFacing)) return nextFacing;
      if (blockId != null && !wrong.contains(blockId)) wrong.add(blockId);
      // A turn the wrong way, where the other way is right: the child meant
      // that, so go on from there (and the move after it isn't to blame).
      if (nextFacing != facing) {
        final other = nextFacing == facing.left ? facing.right : facing.left;
        if (closer(at, other)) return other;
      }
      return null;
    },
  );
  return wrong;
}

/// For a program built around one loop (a repeat, the Magic Block or until
/// the flag) with plain blocks in and around it: the blocks to change,
/// found by comparing it with the right answer of the same shape that's
/// closest to it. Every way the shortest route can repeat is tried (where
/// the loop starts, what it holds, how often it runs), so the child's own
/// choice of answer counts. The blocks that are extra or don't match are
/// wrong, and so is a loop that runs the wrong number of times. Missing
/// blocks have nothing to ring. Null when the program isn't built that way
/// (no loop, two loops, loops inside loops, conditions, the Step Box): then
/// [offTrackBlocks] judges it step by step.
///
/// Step by step can't see a loop's mistakes: a magic block with one step too
/// many walks the route the first time and only goes astray the second.
List<String>? loopShapeMistakes(Level level, Program program) {
  final route = solve(level)?.body;
  if (route == null) return null;
  final steps = [for (final step in route) _token(step)!];

  // The child's program: plain blocks in the main row, and one loop.
  final main = <_Block>[];
  _Loop? loop;
  for (final instruction in program.body) {
    if (_token(instruction) case final token?) {
      main.add((token: token, id: instruction.blockId));
      continue;
    }
    final (kind, body, times) = switch (instruction) {
      Call() => (_LoopKind.star, program.procedure, null),
      Repeat(:final times, :final body) => (_LoopKind.repeat, body, times),
      RepeatUntilGoal(:final body) => (_LoopKind.until, body, null),
      _ => (null, const <Instruction>[], null),
    };
    if (kind == null) return null;
    if (loop != null && (loop.kind != kind || kind != _LoopKind.star)) {
      return null;
    }
    final blocks = <_Block>[];
    for (final inner in body) {
      final token = _token(inner);
      if (token == null) return null;
      blocks.add((token: token, id: inner.blockId));
    }
    loop ??= (kind: kind, id: instruction.blockId, body: blocks, times: times);
    main.add((token: _loopToken, id: instruction.blockId));
  }
  if (loop == null) return null;

  // Every right answer of that shape: the route as a start, a part that
  // repeats (the last round may stop early, on the flag), and an end.
  ({int cost, List<String> wrong})? best;
  for (var unit = 1; unit <= steps.length ~/ 2; unit++) {
    for (var start = 0; start + unit <= steps.length; start++) {
      final shape = steps.sublist(start, start + unit);
      var full = 0;
      while (start + (full + 1) * unit <= steps.length &&
          _same(
            steps.sublist(start + full * unit, start + (full + 1) * unit),
            shape,
          )) {
        full++;
      }
      // A last part round that runs to the flag also counts.
      final rest = steps.sublist(start + full * unit);
      final partial =
          rest.isNotEmpty &&
          rest.length < unit &&
          _same(rest, shape.sublist(0, rest.length));
      // Any number of rounds from two, the rest written out after the loop,
      // or with that last part round run by the loop.
      for (final (rounds, end) in [
        for (var r = 2; r <= full; r++) (r, start + r * unit),
        if (partial) (full + 1, steps.length),
      ]) {
        if (rounds < 2) continue;
        if (loop.kind == _LoopKind.until && end != steps.length) continue;
        final answerMain = [
          ...steps.sublist(0, start),
          if (loop.kind == _LoopKind.star)
            for (var i = 0; i < rounds; i++) _loopToken
          else
            _loopToken,
          ...steps.sublist(end),
        ];
        final (mainCost, mainWrong) = _compare(main, answerMain);
        final (bodyCost, bodyWrong) = _compare(loop.body, shape);
        final countWrong =
            loop.kind == _LoopKind.repeat && loop.times != rounds;
        final cost = mainCost + bodyCost + (countWrong ? 1 : 0);
        if (best != null && cost >= best.cost) continue;
        best = (
          cost: cost,
          wrong: [...mainWrong, if (countWrong) ?loop.id, ...bodyWrong],
        );
      }
    }
  }
  return best?.wrong;
}

typedef _Block = ({String token, String? id});
typedef _Loop = ({_LoopKind kind, String? id, List<_Block> body, int? times});

enum _LoopKind { star, repeat, until }

const _loopToken = 'loop';

/// A plain block's kind, or null for anything else.
String? _token(Instruction instruction) => switch (instruction) {
  Move(steps: 1) => 'move',
  TurnLeft() => 'left',
  TurnRight() => 'right',
  _ => null,
};

bool _same(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// How many blocks must change, be added or go for [blocks] to read as
/// [answer], and the ids of the blocks that must change or go.
(int, List<String>) _compare(List<_Block> blocks, List<String> answer) {
  final n = blocks.length, m = answer.length;
  final cost = List.generate(n + 1, (i) => List.filled(m + 1, 0));
  for (var i = 0; i <= n; i++) {
    cost[i][0] = i;
  }
  for (var j = 0; j <= m; j++) {
    cost[0][j] = j;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final keep = blocks[i - 1].token == answer[j - 1] ? 0 : 1;
      cost[i][j] = [
        cost[i - 1][j - 1] + keep,
        cost[i - 1][j] + 1,
        cost[i][j - 1] + 1,
      ].reduce((a, b) => a < b ? a : b);
    }
  }
  final wrong = <String>[];
  var i = n, j = m;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      final keep = blocks[i - 1].token == answer[j - 1] ? 0 : 1;
      if (cost[i][j] == cost[i - 1][j - 1] + keep) {
        if (keep == 1) wrong.addAll([?blocks[i - 1].id]);
        i--;
        j--;
        continue;
      }
    }
    if (i > 0 && cost[i][j] == cost[i - 1][j] + 1) {
      wrong.addAll([?blocks[i - 1].id]);
      i--;
    } else {
      j--;
    }
  }
  return (cost[n][m], wrong.reversed.toList());
}
