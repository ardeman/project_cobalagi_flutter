import 'dart:math';
import 'dart:ui';

import 'package:cobalagi/engine/world/grid_point.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/play/view/world/ink.dart';
import 'package:cobalagi/features/play/view/world/planet_piece.dart';
import 'package:cobalagi/features/play/view/world/world_theme.dart';

/// How much the board tilts away from the child: the ground is drawn this
/// much shorter than wide, and upright things (obstacles, the finish, stars,
/// hint marks, the robot) are stretched back by its inverse where they
/// stand, so they stand up instead of lying flat. See `TiltedViewport`.
const tilt = 0.8;

/// Stands what is drawn after it upright on the tilted board, around the
/// point [base] (in the same, upright, frame) where it touches the ground.
void standUp(Canvas canvas, Offset base) => canvas
  ..translate(base.dx, base.dy)
  ..scale(1, 1 / tilt)
  ..translate(-base.dx, -base.dy);

/// The board: a piece of the planet's surface floating in the starry sky,
/// cut a little wider than the board, with the path's tiles raised on it and
/// the planet's obstacles and odds and ends ([Decor]) on the ground off it.
/// One unit is one tile. The puzzle's world (`BoardComponent`) and the
/// story's arrival scenes both paint it, so a scene shows the real board.
class BoardPainter {
  BoardPainter(
    this.level,
    this.theme, {
    this.leftRoom = 0,
    this.bare = const {},
  });

  final Level level;
  final WorldTheme theme;

  /// Extra ground left of the board, in tiles (where a story's ship lands).
  final double leftRoom;

  /// Obstacle tiles drawn as bare ground, where a story stands its own
  /// props.
  final Set<GridPoint> bare;

  late final _floor = Paint()..color = theme.floor;
  late final _floorEdge = Paint()..color = theme.floorEdge;
  late final _tileSide = Paint()
    ..color = Color.lerp(theme.floorEdge, const Color(0xFF000000), 0.2)!;
  late final _ground = Paint()..color = theme.ground;
  late final _groundSide = Paint()..color = theme.groundSide;

  /// Each path tile's outline, in Koba's navy, so the path reads as drawn
  /// like Koba.
  static final _tileOutline = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.022;
  static final _edge = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.03
    ..strokeJoin = StrokeJoin.round;

  /// How far the planet's piece reaches past the board, and how thick it is.
  static const _margin = 0.32, _depth = 0.38, _tileDepth = 0.07;

  /// The piece's outline: the board's rectangle with rounded corners and a
  /// gently uneven edge, the same every time for a level.
  late final Path _piece = pieceOutline(
    Rect.fromLTWH(
      -_margin - leftRoom,
      -_margin,
      level.width + 2 * _margin + leftRoom,
      level.height + 2 * _margin,
    ),
    radius: 0.7,
    unit: 1,
    random: Random(level.width * 31 + level.height),
  );

  bool _isPath(int x, int y) =>
      x >= 0 &&
      y >= 0 &&
      x < level.width &&
      y < level.height &&
      level.tiles[y][x] == Tile.floor;

  late final List<RRect> _tiles = [
    for (var y = 0; y < level.height; y++)
      for (var x = 0; x < level.width; x++)
        if (_isPath(x, y))
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1).deflate(0.05),
            const Radius.circular(0.16),
          ),
  ];

  /// The sky behind, never changing.
  late final Picture _sky = _record(
    (canvas) => drawSky(
      canvas,
      Rect.fromLTWH(
        -level.width.toDouble(),
        -level.height.toDouble(),
        level.width * 3.0,
        level.height * 3.0,
      ),
    ),
  );

  /// The planet's surface, its odds and ends, and the path's tiles: all flat
  /// on the ground, so drawn once.
  late final Picture _surface = _record(_drawSurface);

  static Picture _record(void Function(Canvas) draw) {
    final recorder = PictureRecorder();
    draw(Canvas(recorder));
    return recorder.endRecording();
  }

  void _drawSurface(Canvas canvas) {
    canvas
      ..drawPath(_piece, _ground)
      ..drawPath(_piece, _edge);
    // Odds and ends on the ground, scattered so no two cells look alike,
    // never on the path.
    final random = Random(level.width * 7 + level.height * 13 + 1);
    final bounds = _piece.getBounds();
    final count = (bounds.width * bounds.height * 1.6).round();
    for (var i = 0; i < count; i++) {
      final at = Offset(
        bounds.left + random.nextDouble() * bounds.width,
        bounds.top + random.nextDouble() * bounds.height,
      );
      final near = Rect.fromCenter(center: at, width: 0.42, height: 0.42);
      final onPath = _tiles.any((tile) => tile.outerRect.overlaps(near));
      if (onPath || !_piece.contains(at)) continue;
      drawDecor(canvas, at, theme.decor, theme.ground, random);
    }
    for (final tile in _tiles) {
      canvas
        ..drawRRect(tile, _floorEdge)
        ..drawRRect(tile, _tileOutline)
        ..drawRRect(tile.deflate(0.05), _floor)
        ..drawRRect(tile.deflate(0.05), _tileOutline);
    }
  }

  /// Where an obstacle's picture reaches, around its tile's centre.
  static const _obstacleBounds = Rect.fromLTWH(-0.6, -0.6, 1.2, 1.2);

  /// Each obstacle, drawn once in Koba's look, and placed a little
  /// differently in its tile (shifted, sized, mirrored) so the planet's
  /// ground never looks stamped out.
  late final List<({Offset at, Image image, double size, bool mirror})>
  _obstacles = [
    for (var y = 0; y < level.height; y++)
      for (var x = 0; x < level.width; x++)
        if (level.tiles[y][x] != Tile.floor && !bare.contains(GridPoint(x, y)))
          () {
            final random = Random(y * 997 + x + 5);
            // A maze's hedges are its walls: they stay lined up.
            final varied = theme.obstacle != Obstacle.hedge;
            return (
              at: Offset(
                x + 0.5 + (varied ? (random.nextDouble() - 0.5) * 0.14 : 0),
                y + 0.5 + (varied ? (random.nextDouble() - 0.5) * 0.1 : 0),
              ),
              image: inkedPiece(
                (canvas) => drawObstacle(
                  canvas,
                  const Rect.fromLTWH(-0.5, -0.5, 1, 1),
                  theme.obstacle,
                  y * 997 + x,
                ),
                bounds: _obstacleBounds,
              ),
              size: varied ? 0.68 + random.nextDouble() * 0.3 : 1.0,
              mirror: varied && random.nextBool(),
            );
          }(),
  ];

  /// Paints the board (on the starry [sky] unless not), turned [upright]
  /// (see `BoardComponent.upright`), in an untilted frame of one unit per
  /// tile: the caller tilts it.
  void paint(Canvas canvas, {double upright = 0, bool sky = true}) {
    // Down the screen, in the board's own (turned) frame: where the sides
    // of the ground and the tiles show.
    final down = Offset(-sin(upright), cos(upright));
    if (sky) canvas.drawPicture(_sky);
    for (var i = 1; i <= 8; i++) {
      canvas.drawPath(_piece.shift(down * (_depth * i / 8)), _groundSide);
    }
    canvas.drawPath(_piece.shift(down * _depth), _edge);
    for (final tile in _tiles) {
      canvas.drawRRect(tile.shift(down * _tileDepth), _tileSide);
    }
    canvas.drawPicture(_surface);
    // Nearer the bottom of the screen draws later, in front.
    double depth(Offset at) => sin(upright) * -at.dx + cos(upright) * at.dy;
    final order = [..._obstacles]
      ..sort((a, b) => depth(a.at).compareTo(depth(b.at)));
    for (final obstacle in order) {
      canvas
        ..save()
        ..translate(obstacle.at.dx, obstacle.at.dy)
        ..rotate(upright);
      standUp(canvas, const Offset(0, 0.28));
      canvas.scale(
        obstacle.mirror ? -obstacle.size : obstacle.size,
        obstacle.size,
      );
      drawInked(canvas, obstacle.image, _obstacleBounds);
      canvas.restore();
    }
  }

  void dispose() {
    _sky.dispose();
    _surface.dispose();
    for (final obstacle in _obstacles) {
      obstacle.image.dispose();
    }
  }
}
