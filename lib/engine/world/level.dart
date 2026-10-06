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
/// `#` wall, `.` floor, `S` start, `G` goal, `*` star.
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
  }) : tiles = List<List<Tile>>.unmodifiable([
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
  }

  factory Level.fromRows({
    required String id,
    required String concept,
    required List<String> rows,
    required Direction startFacing,
    required Set<InstructionKind> palette,
    int? maxBlocks,
    Program? starter,
  }) {
    GridPoint? start;
    GridPoint? goal;
    final stars = <GridPoint>{};
    final tiles = <List<Tile>>[];
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
            throw LevelFormatException('unknown tile "$char" at $point');
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

  /// Upper limit on blocks in the program, or null for no limit.
  final int? maxBlocks;

  /// Blocks already placed when the puzzle opens. Debugging puzzles start
  /// with a program that has a bug for the child to find and fix.
  final Program? starter;

  int get width => tiles.first.length;

  int get height => tiles.length;

  bool contains(GridPoint p) =>
      p.x >= 0 && p.y >= 0 && p.x < width && p.y < height;

  bool isOpen(GridPoint p) => contains(p) && tiles[p.y][p.x] == Tile.floor;

  List<String> get rows => [
    for (var y = 0; y < height; y++)
      String.fromCharCodes([
        for (var x = 0; x < width; x++) _charAt(GridPoint(x, y)).codeUnitAt(0),
      ]),
  ];

  String _charAt(GridPoint p) {
    if (tiles[p.y][p.x] == Tile.wall) return '#';
    if (p == start) return 'S';
    if (p == goal) return 'G';
    if (stars.contains(p)) return '*';
    return '.';
  }

  /// Identifies the puzzle layout regardless of [id], to avoid serving repeats.
  String get fingerprint => '${startFacing.name}|${rows.join('/')}';

  Map<String, Object?> toJson() => {
    'id': id,
    'concept': concept,
    'facing': startFacing.name,
    'palette': [for (final kind in palette) kind.name],
    if (maxBlocks != null) 'maxBlocks': maxBlocks,
    if (starter != null) 'starter': programToJson(starter!),
    'rows': rows,
  };
}
