import 'dart:math';

import '../../engine/generator/puzzle_generator.dart';
import '../../engine/interpreter/interpreter.dart';
import '../../engine/program/instruction.dart';
import '../../engine/program/program.dart';
import '../../engine/world/direction.dart';
import '../../engine/world/level.dart';
import 'pretest_question.dart';

const patternShapes = ['circle', 'square', 'triangle', 'heart'];

/// Builds pretest questions from the vocabulary. Deterministic for a given
/// [Random] seed.
final class PretestGenerator {
  PretestGenerator({
    required this.objects,
    required this.colors,
    required Random random,
  }) : _random = random {
    if (objects.length < 4 || colors.length < 3) {
      throw ArgumentError('need at least 4 objects and 3 colors');
    }
  }

  factory PretestGenerator.fromJson(
    Map<String, Object?> vocabulary,
    Random random,
  ) => PretestGenerator(
    objects: [...(vocabulary['objects']! as List).cast<String>()],
    colors: [...(vocabulary['colors']! as List).cast<String>()],
    random: random,
  );

  final List<String> objects;
  final List<String> colors;
  final Random _random;

  PretestQuestion question(PretestSkill skill, int level) {
    RangeError.checkValueInInterval(level, 1, maxSkillLevel, 'level');
    return switch (skill) {
      PretestSkill.reading => _reading(level),
      PretestSkill.counting => _counting(level),
      PretestSkill.direction => _direction(level),
      PretestSkill.pattern => _pattern(level),
      PretestSkill.sequencing => _sequencing(level),
    };
  }

  T _pick<T>(List<T> from) => from[_random.nextInt(from.length)];

  List<T> _pickDistinct<T>(List<T> from, int count) =>
      ([...from]..shuffle(_random)).take(count).toList();

  /// Shuffles [answer] in among [others]; returns the options and the index.
  (List<T>, int) _withAnswer<T>(T answer, List<T> others) {
    final options = [answer, ...others]..shuffle(_random);
    return (options, options.indexOf(answer));
  }

  /// Level 1: 2 pictures. Level 2: 3 pictures. Level 3: color + object, where
  /// the wrong pictures share either the color or the object.
  ReadingQuestion _reading(int level) {
    if (level < 3) {
      final picked = _pickDistinct(objects, level + 1);
      final answer = Picture(picked.first);
      final (options, correct) = _withAnswer(answer, [
        for (final o in picked.skip(1)) Picture(o),
      ]);
      return ReadingQuestion(
        level: level,
        correct: correct,
        words: answer,
        options: options,
      );
    }
    final [object, otherObject] = _pickDistinct(objects, 2);
    final [color, otherColor] = _pickDistinct(colors, 2);
    final answer = Picture(object, color);
    final (options, correct) = _withAnswer(answer, [
      Picture(object, otherColor),
      Picture(otherObject, color),
    ]);
    return ReadingQuestion(
      level: level,
      correct: correct,
      words: answer,
      options: options,
    );
  }

  /// Level 1: 1–3 things. Level 2: 4–6. Level 3: 7–10.
  CountingQuestion _counting(int level) {
    final count = switch (level) {
      1 => 1 + _random.nextInt(3),
      2 => 4 + _random.nextInt(3),
      _ => 7 + _random.nextInt(4),
    };
    final others = [
      if (count > 1) count - 1,
      count + 1,
      if (count == 1) count + 2,
    ];
    final (options, correct) = _withAnswer(count, others);
    return CountingQuestion(
      level: level,
      correct: correct,
      object: _pick(objects),
      count: count,
      options: options,
    );
  }

  /// Level 1: left or right side. Level 2: turn while facing up. Level 3:
  /// turn while facing down or sideways, where left and right feel swapped.
  PretestQuestion _direction(int level) {
    if (level == 1) {
      final target = _pick(Side.values);
      return SideQuestion(level: 1, correct: target.index, target: target);
    }
    final facing = level == 2
        ? Direction.north
        : _pick([Direction.south, Direction.east, Direction.west]);
    final turn = _pick(Side.values);
    final answer = turn == Side.left ? facing.left : facing.right;
    final wrong = turn == Side.left ? facing.right : facing.left;
    final (options, correct) = _withAnswer(answer, [wrong, facing]);
    return TurnQuestion(
      level: level,
      correct: correct,
      facing: facing,
      turn: turn,
      options: options,
    );
  }

  /// Level 1: AB AB. Level 2: ABC ABC. Level 3: AAB AAB.
  PatternQuestion _pattern(int level) {
    final shapes = _pickDistinct(patternShapes, 3);
    final paints = _pickDistinct(colors, 3);
    final unit = [for (var i = 0; i < 3; i++) Picture(shapes[i], paints[i])];
    final cycle = switch (level) {
      1 => [unit[0], unit[1]],
      2 => [unit[0], unit[1], unit[2]],
      _ => [unit[0], unit[0], unit[1]],
    };
    final shown = [for (var i = 0; i < 6; i++) cycle[i % cycle.length]];
    final answer = cycle[6 % cycle.length];
    final (options, correct) = _withAnswer(answer, [
      for (final p in unit)
        if (p != answer) p,
    ]);
    return PatternQuestion(
      level: level,
      correct: correct,
      sequence: shown,
      options: options,
    );
  }

  /// Level 1: two steps straight ahead. Level 2: a path with one turn.
  /// Level 3: a path with two turns. Wrong options are near-misses that fail.
  SequencingQuestion _sequencing(int level) {
    final (Level map, List<Instruction> steps) = level == 1
        ? (
            Level.fromRows(
              id: 'pretest-seq-1',
              concept: 'sequencing',
              rows: ['#####', '#S.G#', '#####'],
              startFacing: Direction.east,
              palette: _palette,
            ),
            const [Move(), Move()],
          )
        : _generatedPath(level);
    final answer = [for (final i in steps) i.kind];
    final wrong = <List<InstructionKind>>[];
    for (final candidate in _nearMisses(answer)..shuffle(_random)) {
      final fails = !runProgram(_program(candidate), map).succeeded;
      if (fails && !wrong.any((w) => _same(w, candidate))) wrong.add(candidate);
      if (wrong.length == 2) break;
    }
    final (options, correct) = _withAnswer(answer, wrong);
    return SequencingQuestion(
      level: level,
      correct: correct,
      map: map,
      options: options,
    );
  }

  static const _palette = {
    InstructionKind.move,
    InstructionKind.turnLeft,
    InstructionKind.turnRight,
  };

  (Level, List<Instruction>) _generatedPath(int level) {
    for (var attempt = 0; ; attempt++) {
      final puzzle = generatePuzzle(
        PuzzleKind.directions,
        difficulty: level == 2 ? 1 : 3,
        seed: _random.nextInt(1 << 30),
      );
      final steps = puzzle.solution.body;
      // Short enough to read at a glance.
      if (steps.length <= (level == 2 ? 4 : 6) || attempt > 50) {
        return (puzzle.level, steps);
      }
    }
  }

  /// Variations of [answer]: a turn flipped, a step dropped or added.
  static List<List<InstructionKind>> _nearMisses(List<InstructionKind> answer) {
    InstructionKind flip(InstructionKind k) => switch (k) {
      InstructionKind.turnLeft => InstructionKind.turnRight,
      InstructionKind.turnRight => InstructionKind.turnLeft,
      _ => k,
    };
    return [
      [for (final k in answer) flip(k)],
      for (var i = 0; i < answer.length; i++)
        if (answer[i] != InstructionKind.move || answer.length > 1)
          [...answer.sublist(0, i), ...answer.sublist(i + 1)],
      [...answer, InstructionKind.move],
      [InstructionKind.turnLeft, ...answer],
      [InstructionKind.turnRight, ...answer],
    ];
  }

  static Program _program(List<InstructionKind> kinds) => Program([
    for (final k in kinds)
      switch (k) {
        InstructionKind.move => const Move(),
        InstructionKind.turnLeft => const TurnLeft(),
        InstructionKind.turnRight => const TurnRight(),
        InstructionKind.repeat ||
        InstructionKind.ifPathClear ||
        InstructionKind.call => throw ArgumentError('only moves and turns'),
      },
  ]);

  static bool _same(List<InstructionKind> a, List<InstructionKind> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((same) => same);
}
