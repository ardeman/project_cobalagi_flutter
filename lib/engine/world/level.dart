import '../examples/example.dart';
import '../program/instruction.dart';
import '../program/program.dart';
import '../program/program_json.dart';
import 'direction.dart';
import 'grid_point.dart';

enum Tile { floor, wall }

class LevelFormatException implements Exception {
  const LevelFormatException(this.message);

  final String message;

  @override
  String toString() => 'LevelFormatException: $message';
}

/// A puzzle: the grid, where the actor starts, the goal, stars to collect and
/// which blocks the editor may offer.
///
/// In JSON the grid is a list of equal-length rows using these characters:
/// `#` wall, `.` floor, `S` start, `G` goal, `*` star, and a letter for a
/// creature standing on a floor tile (`things` in JSON maps the letter to
/// its colour, shape and size). A creature is open ground only when the
/// lesson's [examples] say it is safe; anything else blocks, like a wall.
/// The eye block still checks [isOpen], so a Teach Koba puzzle is an
/// Otherwise program.
///
/// A level may have [moreBoards] (`moreBoards` in JSON: a list of row lists):
/// the same program must reach the finish on each of them too, so a child
/// can't just count the steps and has to look ahead.
final class Level {
  Level({
    required this.id,
    required this.concept,
    required List<List<Tile>> tiles,
    required this.start,
    required this.startFacing,
    required this.goal,
    Set<GridPoint> stars = const {},
    required Set<InstructionKind> palette,
    this.maxBlocks,
    this.starter,
    List<Level> moreBoards = const [],
    Map<GridPoint, ExampleThing> things = const {},
    Map<GridPoint, String> marks = const {},
    Map<String, ExampleThing> catalog = const {},
    List<LabeledExample> examples = const [],
    List<LabeledExample> asks = const [],
    List<SortRound> rounds = const [],
  }) : moreBoards = List.unmodifiable(moreBoards),
       things = Map.unmodifiable(things),
       marks = Map.unmodifiable(marks),
       catalog = Map.unmodifiable(catalog),
       examples = List.unmodifiable(examples),
       asks = List.unmodifiable(asks),
       rounds = List.unmodifiable(rounds),
       tiles = List<List<Tile>>.unmodifiable([
         for (final row in tiles) List<Tile>.unmodifiable(row),
       ]),
       stars = Set.unmodifiable(stars),
       palette = Set.unmodifiable(palette) {
    if (tiles.isEmpty || tiles.first.isEmpty) {
      throw const LevelFormatException('grid is empty');
    }
    if (tiles.any((row) => row.length != width)) {
      throw const LevelFormatException('rows have different lengths');
    }
    for (final p in [start, goal, ...stars]) {
      if (!isOpen(p)) throw LevelFormatException('$p is not on open floor');
    }
    if (palette.isEmpty) throw const LevelFormatException('palette is empty');
    for (final board in moreBoards) {
      if (board.width != width || board.height != height) {
        throw const LevelFormatException('boards have different sizes');
      }
      if (board.start != start || board.startFacing != startFacing) {
        throw const LevelFormatException('boards start differently');
      }
    }
    for (final point in things.keys) {
      if (!contains(point) || tiles[point.y][point.x] != Tile.floor) {
        throw LevelFormatException('$point is not a floor tile for a thing');
      }
      if (classify(things[point]!, examples) == null) {
        throw LevelFormatException('the examples are not sure about $point');
      }
    }
    for (final round in rounds) {
      for (final index in round.show) {
        if (index < 0 || index >= examples.length) {
          throw LevelFormatException('round shows example $index');
        }
      }
      for (final index in round.ask) {
        if (index < 0 || index >= asks.length) {
          throw LevelFormatException('round asks $index');
        }
      }
    }
  }

  factory Level.fromRows({
    required String id,
    required String concept,
    required List<String> rows,
    required Direction startFacing,
    required Set<InstructionKind> palette,
    int? maxBlocks,
    Program? starter,
    List<List<String>> moreBoards = const [],
    Map<String, ExampleThing> catalog = const {},
    List<LabeledExample> examples = const [],
    List<LabeledExample> asks = const [],
    List<SortRound> rounds = const [],
  }) {
    GridPoint? start;
    GridPoint? goal;
    final stars = <GridPoint>{};
    final tiles = <List<Tile>>[];
    final things = <GridPoint, ExampleThing>{};
    final marks = <GridPoint, String>{};
    for (var y = 0; y < rows.length; y++) {
      final row = <Tile>[];
      for (var x = 0; x < rows[y].length; x++) {
        final char = rows[y][x];
        final point = GridPoint(x, y);
        switch (char) {
          case '#':
            row.add(Tile.wall);
            continue;
          case '.':
            break;
          case 'S':
            if (start != null) throw const LevelFormatException('two starts');
            start = point;
          case 'G':
            if (goal != null) throw const LevelFormatException('two goals');
            goal = point;
          case '*':
            stars.add(point);
          default:
            final thing = catalog[char];
            if (thing == null || char.length != 1) {
              throw LevelFormatException('unknown tile "$char" at $point');
            }
            things[point] = thing;
            marks[point] = char;
        }
        row.add(Tile.floor);
      }
      tiles.add(row);
    }
    if (start == null) throw const LevelFormatException('no start (S)');
    if (goal == null) throw const LevelFormatException('no goal (G)');
    return Level(
      id: id,
      concept: concept,
      tiles: tiles,
      start: start,
      startFacing: startFacing,
      goal: goal,
      stars: stars,
      palette: palette,
      maxBlocks: maxBlocks,
      starter: starter,
      things: things,
      marks: marks,
      catalog: catalog,
      examples: examples,
      asks: asks,
      rounds: rounds,
      moreBoards: [
        for (final (i, board) in moreBoards.indexed)
          Level.fromRows(
            id: '$id:${i + 2}',
            concept: concept,
            rows: board,
            startFacing: startFacing,
            palette: palette,
            maxBlocks: maxBlocks,
            starter: starter,
            catalog: catalog,
            examples: examples,
            asks: asks,
            rounds: rounds,
          ),
      ],
    );
  }

  factory Level.fromJson(Map<String, Object?> json) {
    try {
      return Level.fromRows(
        id: json['id']! as String,
        concept: json['concept']! as String,
        rows: (json['rows']! as List).cast<String>(),
        startFacing: Direction.values.byName(json['facing']! as String),
        palette: {
          for (final name in (json['palette']! as List).cast<String>())
            InstructionKind.values.byName(name),
        },
        maxBlocks: json['maxBlocks'] as int?,
        starter: json.containsKey('starter')
            ? programFromJson(json['starter'])
            : null,
        moreBoards: [
          for (final board in (json['moreBoards'] as List?) ?? const [])
            (board as List).cast<String>(),
        ],
        catalog: {
          for (final MapEntry(:key, :value)
              in ((json['things'] as Map?) ?? const {})
                  .cast<String, Object?>()
                  .entries)
            key: ExampleThing.fromJson((value as Map).cast<String, Object?>()),
        },
        examples: [
          for (final example in (json['examples'] as List?) ?? const [])
            LabeledExample.fromJson((example as Map).cast<String, Object?>()),
        ],
        asks: [
          for (final example in (json['asks'] as List?) ?? const [])
            LabeledExample.fromJson((example as Map).cast<String, Object?>()),
        ],
        rounds: [
          for (final round in (json['rounds'] as List?) ?? const [])
            SortRound.fromJson((round as Map).cast<String, Object?>()),
        ],
      );
    } on LevelFormatException {
      rethrow;
    } catch (e) {
      throw LevelFormatException('invalid level JSON: $e');
    }
  }

  final String id;

  /// Skill-map concept this level practises, e.g. `sequencing`.
  final String concept;
  final List<List<Tile>> tiles;
  final GridPoint start;
  final Direction startFacing;
  final GridPoint goal;
  final Set<GridPoint> stars;
  final Set<InstructionKind> palette;

  /// Creatures standing on floor tiles, keyed by the cell they occupy.
  final Map<GridPoint, ExampleThing> things;

  /// The grid letter of each [things] cell, so rows round-trip.
  final Map<GridPoint, String> marks;

  /// Grid letter to the creature it draws, as in the level JSON.
  final Map<String, ExampleThing> catalog;

  /// Labeled pictures the lesson trains on. The eye uses all of them.
  final List<LabeledExample> examples;

  /// New pictures Koba tries after a sorting round. Not part of [examples].
  final List<LabeledExample> asks;

  /// Sorting rounds, in order. Empty on a practice puzzle or a demo.
  final List<SortRound> rounds;

  /// Upper limit on blocks in the program, or null for no limit.
  final int? maxBlocks;

  /// Blocks already placed when the puzzle opens. Debugging puzzles start
  /// with a program that has a bug for the child to find and fix.
  final Program? starter;

  /// Other boards the same program must also solve (see the class comment).
  /// Each is a plain level with the same size, start and palette.
  final List<Level> moreBoards;

  /// Every board a run must solve: this one first, then [moreBoards].
  List<Level> get boards => [this, ...moreBoards];

  int get width => tiles.first.length;

  int get height => tiles.length;

  bool contains(GridPoint p) =>
      p.x >= 0 && p.y >= 0 && p.x < width && p.y < height;

  bool isOpen(GridPoint p) {
    if (!contains(p) || tiles[p.y][p.x] != Tile.floor) return false;
    final thing = things[p];
    if (thing == null) return true;
    return classify(thing, examples) == true;
  }

  List<String> get rows => [
    for (var y = 0; y < height; y++)
      String.fromCharCodes([
        for (var x = 0; x < width; x++) _charAt(GridPoint(x, y)).codeUnitAt(0),
      ]),
  ];

  String _charAt(GridPoint p) {
    if (tiles[p.y][p.x] == Tile.wall) return '#';
    final mark = marks[p];
    if (mark != null) return mark;
    if (p == start) return 'S';
    if (p == goal) return 'G';
    if (stars.contains(p)) return '*';
    return '.';
  }

  /// Identifies the puzzle layout regardless of [id], to avoid serving repeats.
  /// Lessons without creatures keep the old text, so saved puzzles still match.
  String get fingerprint {
    final layout = [
      for (final board in boards) '${startFacing.name}|${board.rows.join('/')}',
    ].join('+');
    if (examples.isEmpty && catalog.isEmpty) return layout;
    final learned = [
      for (final example in examples)
        '${example.thing.colour.name}:${example.thing.shape.name}:${example.thing.size.name}:${example.safe ? 1 : 0}',
    ].join(',');
    final kinds = (catalog.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        .map(
          (entry) =>
              '${entry.key}=${entry.value.colour.name}:${entry.value.shape.name}:${entry.value.size.name}',
        )
        .join(',');
    return '$layout|$learned|$kinds';
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'concept': concept,
    'facing': startFacing.name,
    'palette': [for (final kind in palette) kind.name],
    if (maxBlocks != null) 'maxBlocks': maxBlocks,
    if (starter != null) 'starter': programToJson(starter!),
    'rows': rows,
    if (moreBoards.isNotEmpty)
      'moreBoards': [for (final board in moreBoards) board.rows],
    if (catalog.isNotEmpty)
      'things': {
        for (final entry in catalog.entries) entry.key: entry.value.toJson(),
      },
    if (examples.isNotEmpty)
      'examples': [for (final example in examples) example.toJson()],
    if (asks.isNotEmpty) 'asks': [for (final ask in asks) ask.toJson()],
    if (rounds.isNotEmpty)
      'rounds': [for (final round in rounds) round.toJson()],
  };
}
