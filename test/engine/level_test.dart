import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/grid_point.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:flutter_test/flutter_test.dart';

Level parse(List<String> rows) => Level.fromRows(
  id: 't',
  concept: 'sequencing',
  rows: rows,
  startFacing: Direction.east,
  palette: {InstructionKind.move},
);

void main() {
  test('parses start, goal, stars and walls', () {
    final level = parse(['#####', '#S*G#', '#####']);
    expect(level.width, 5);
    expect(level.height, 3);
    expect(level.start, const GridPoint(1, 1));
    expect(level.goal, const GridPoint(3, 1));
    expect(level.stars, {const GridPoint(2, 1)});
    expect(level.isOpen(const GridPoint(0, 1)), isFalse);
    expect(level.isOpen(const GridPoint(9, 9)), isFalse);
  });

  test('round-trips through JSON', () {
    final json = {
      'id': 'seq-01',
      'concept': 'sequencing',
      'facing': 'north',
      'palette': ['move', 'turnLeft'],
      'maxBlocks': 4,
      'rows': ['#G#', '#.#', '#S#'],
    };
    final level = Level.fromJson(json);
    expect(level.startFacing, Direction.north);
    expect(level.palette, {InstructionKind.move, InstructionKind.turnLeft});
    expect(level.toJson(), json);
  });

  test('rejects malformed grids', () {
    for (final rows in [
      ['#.G#'], // no start
      ['#S.#'], // no goal
      ['SG', 'S.'], // two starts
      ['S.G', '..'], // ragged rows
      ['S?G'], // unknown tile
    ]) {
      expect(() => parse(rows), throwsA(isA<LevelFormatException>()));
    }
    expect(
      () => Level.fromJson({'id': 'x'}),
      throwsA(isA<LevelFormatException>()),
    );
  });

  test('fingerprint ignores id but not layout or facing', () {
    final a = parse(['S.G']);
    final b = Level.fromRows(
      id: 'other',
      concept: 'sequencing',
      rows: ['S.G'],
      startFacing: Direction.east,
      palette: {InstructionKind.move},
    );
    expect(a.fingerprint, b.fingerprint);
    expect(a.fingerprint, isNot(parse(['SG.']).fingerprint));
  });
}
