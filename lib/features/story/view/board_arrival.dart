import 'dart:math';
import 'dart:ui';

import 'package:flutter/animation.dart';

import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/grid_point.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/play/view/world/board_painter.dart';
import 'package:cobalagi/features/play/view/world/ink.dart';
import 'package:cobalagi/features/play/view/world/world_theme.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/story_paint.dart';

/// An arrival played on a small puzzle of the planet, drawn like its real
/// board: while the narrator sets the scene the ship lands beside it and
/// Koba rolls onto the start; in Koba's beat the puzzle's blocks drop into
/// a program row one after another, Go is pressed, and Koba runs them tile
/// by tile, each block lit while it runs, collecting the stars on the way
/// to the finish. The run comes from the real interpreter, so the scene
/// shows exactly what the blocks do.
abstract class BoardArrival extends ArrivalScene {
  const BoardArrival(super.concept);

  /// The board as in a lesson pack: `#` an obstacle, `.` path, `S` the
  /// start, `G` the finish, `*` a star.
  List<String> get rows;

  /// The way Koba faces on the start.
  Direction get facing;

  /// The program Koba runs.
  List<BlockType> get blocks;

  /// The puzzle, its blocks and the run, built once.
  BoardPlay get play => _plays[concept] ??= BoardPlay(this);

  // Kept for the app's life: a few small pictures per planet.
  static final _plays = <String, BoardPlay>{};

  @override
  Duration get kobaLength => const Duration(milliseconds: 7000);

  /// Koba's beat: when the blocks drop in, when Go is pressed, and when the
  /// run plays (0 to 1).
  static const _dropsFrom = 0.03, _dropsTo = 0.28, _go = 0.3;
  static const _runFrom = 0.34, _runTo = 0.92;

  double _dropAt(int i) =>
      _dropsFrom + (_dropsTo - _dropsFrom) * i / max(1, blocks.length - 1);

  /// When step [i] of the run starts, and how long each lasts.
  double _stepAt(int i) => _runFrom + i * _stepLength;
  double get _stepLength => (_runTo - _runFrom) / play.steps.length;

  @override
  List<(double, SoundEffect)> get effects => [
    for (var i = 0; i < blocks.length; i++)
      (_dropAt(i) + 0.03, SoundEffect.drop),
    for (final (i, step) in play.steps.indexed) ...[
      (_stepAt(i), step.turn ? SoundEffect.turn : SoundEffect.step),
      if (step.star) (_stepAt(i + 1), SoundEffect.star),
    ],
    (_runTo, SoundEffect.goal),
  ];

  // Unused: the board scene paints itself.
  @override
  void paintPlanet(ArrivalStage s) {}

  @override
  void paintKobaBeat(ArrivalStage s) {}

  @override
  void paint(Canvas canvas, Rect stage, StoryFrame frame, StoryArt? art) {
    final s = ArrivalStage(canvas, stage, frame, art);
    final b = _BoardLayout(s, play);
    canvas
      ..save()
      ..translate(b.origin.dx, b.origin.dy)
      ..scale(b.tile, b.tile * tilt);
    play.board.paint(canvas, sky: false);
    canvas.restore();

    final kobaSize = b.tile * 1.1;
    final ship = b.at(-1.5, 2.2);
    final shipSize = b.tile * 2.7;
    if (frame.beat == 0) {
      _paintStars(s, b, const {});
      _paintFinish(s, b);
      paintLanding(
        s,
        ship: ship,
        shipSize: shipSize,
        to: b.foot(play.level.start.x + 0.0, play.level.start.y + 0.0),
        kobaSize: kobaSize,
      );
      return;
    }
    paintLanded(s, ship: ship, shipSize: shipSize);
    _paintProgram(s, b);

    // Where the run is: the step playing and how far through it.
    final into = ((s.t - _runFrom) / _stepLength).clamp(
      0.0,
      play.steps.length.toDouble(),
    );
    final done = into >= play.steps.length;
    final now = done ? play.steps.length - 1 : into.floor();
    final step = play.steps[now];
    final p = done ? 1.0 : Curves.easeInOut.transform(into - now);
    final taken = {
      for (final (i, earlier) in play.steps.indexed)
        if (earlier.star && (i < now || done)) earlier.to,
    };
    // A star pops as Koba arrives on it.
    final popping = !done && step.star && p > 0.85 ? step.to : null;

    final x = storyLerp(step.from.x + 0.0, step.to.x + 0.0, p);
    final y = storyLerp(step.from.y + 0.0, step.to.y + 0.0, p);
    final angle = storyLerp(step.fromAngle, step.toAngle, p);
    // Things further up the board are painted first.
    final kobaFirst = y < play.level.goal.y;
    if (!kobaFirst) _paintFinish(s, b);
    _paintStars(s, b, taken, popping: popping);
    _paintKoba(
      s,
      b,
      x,
      y,
      angle,
      size: kobaSize,
      cheer: s.t >= _runTo,
      rolling: s.t >= _runFrom && !done,
    );
    if (kobaFirst) _paintFinish(s, b);
  }

  /// The program row over the board: each block drops into its place, then
  /// Go is pressed and the block running glows.
  void _paintProgram(ArrivalStage s, _BoardLayout b) {
    final canvas = s.canvas;
    final size = s.u * 0.1;
    final gap = s.u * 0.022;
    final count = blocks.length + 1;
    final width = count * size + (count - 1) * gap;
    final centre = Offset(s.box.center.dx, s.box.top + s.u * 0.15);
    final show = Curves.easeOut.transform((s.t / 0.05).clamp(0, 1));
    final row = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: centre,
        width: width + gap * 2,
        height: size + gap * 2,
      ),
      Radius.circular(size * 0.36),
    );
    canvas
      ..drawRRect(
        row,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.16 * show),
      )
      ..drawRRect(
        row,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45 * show)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, s.u * 0.004),
      );
    Offset slot(int i) =>
        Offset(centre.dx - width / 2 + size / 2 + i * (size + gap), centre.dy);
    final running = s.t >= _runFrom && s.t < _runTo
        ? play.steps[((s.t - _runFrom) / _stepLength).floor()].block
        : null;
    for (final (i, type) in blocks.indexed) {
      final drop = ((s.t - _dropAt(i)) / 0.04).clamp(0.0, 1.0);
      if (drop == 0) continue;
      final fall = Curves.easeOutBack.transform(drop);
      paintBlock(
        canvas,
        type,
        slot(i) - Offset(0, (1 - fall) * s.u * 0.08),
        size,
        glow: running == i,
      );
    }
    // Go, pressed once every block is in.
    final press = ((s.t - _go) / 0.04).clamp(0.0, 1.0);
    final c = slot(blocks.length);
    final r = size * 0.5 * (1 - 0.15 * sin(pi * press));
    if (press > 0 && press < 1) {
      canvas.drawCircle(
        c,
        r * 1.25,
        Paint()
          ..color = storyGold
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.12),
      );
    }
    final go = Path()
      ..moveTo(c.dx - r * 0.3, c.dy - r * 0.45)
      ..lineTo(c.dx + r * 0.5, c.dy)
      ..lineTo(c.dx - r * 0.3, c.dy + r * 0.45)
      ..close();
    canvas
      ..drawCircle(c, r, Paint()..color = const Color(0xFF3DBE6A))
      ..drawCircle(
        c,
        r,
        Paint()
          ..color = storyInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, size * 0.05),
      )
      ..drawPath(go, Paint()..color = const Color(0xFFFFFFFF));
  }

  /// The stars still on the board ([taken] ones gone), the one [popping]
  /// growing and fading as Koba takes it.
  void _paintStars(
    ArrivalStage s,
    _BoardLayout b,
    Set<GridPoint> taken, {
    GridPoint? popping,
  }) {
    for (final star in play.level.stars) {
      if (taken.contains(star)) continue;
      final pop = star == popping
          ? ((s.t - _stepAt(play.steps.indexWhere((e) => e.to == star))) /
                        _stepLength -
                    0.85) /
                0.15
          : 0.0;
      paintStoryStar(
        s.canvas,
        b.at(star.x + 0.5, star.y + 0.5) -
            Offset(
              0,
              b.tile * (0.12 + 0.03 * sin(s.time * 3 + star.x) + pop * 0.3),
            ),
        b.tile * 0.3 * (1 + 0.5 * pop),
        opacity: 1 - pop.clamp(0, 1),
        turn: s.time + star.x,
      );
    }
  }

  /// The finish on its tile, standing up as in the world.
  void _paintFinish(ArrivalStage s, _BoardLayout b) {
    final goal = play.level.goal;
    final pulse = 1 + 0.04 * sin(s.time * 4);
    s.canvas
      ..save()
      ..translate(
        b.at(goal.x + 0.5, goal.y + 0.82).dx,
        b.at(goal.x + 0.5, goal.y + 0.82).dy,
      )
      ..scale(b.tile * pulse)
      ..translate(-0.5, -0.82);
    drawInked(s.canvas, play.finish, BoardPlay.finishBounds);
    s.canvas.restore();
  }

  /// Koba on tile ([x], [y]) facing [angle] (clockwise from up the board),
  /// shown as in the world: its back going up, its front coming down, its
  /// side across, squeezed for a moment as it turns between them.
  void _paintKoba(
    ArrivalStage s,
    _BoardLayout b,
    double x,
    double y,
    double angle, {
    required double size,
    required bool cheer,
    required bool rolling,
  }) {
    final art = s.art;
    if (art == null) return;
    final foot = b.foot(x, y);
    s.canvas.drawOval(
      Rect.fromCenter(
        center: foot,
        width: b.tile * 0.64,
        height: b.tile * 0.16,
      ),
      Paint()..color = const Color(0x40000000),
    );
    final quarter = (angle / (pi / 2)).round();
    final between = (angle / (pi / 2) - quarter).abs() * 2;
    final facing = Direction.values[quarter % 4];
    final face = cheer ? RobotFace.cheer : RobotFace.normal;
    s.canvas
      ..save()
      ..translate(foot.dx, foot.dy)
      ..scale(1 - 0.6 * between, 1)
      ..translate(-foot.dx, -foot.dy);
    s.koba(
      foot - Offset(0, rolling ? 0 : sin(s.time * 2.4).abs() * b.tile * 0.02),
      size: size,
      face: face,
      back: facing == Direction.north && !cheer,
      front: facing == Direction.south,
      mirror: facing == Direction.west,
    );
    s.canvas.restore();
  }
}

/// Where a [BoardArrival]'s board lies in the scene: [tile] wide tiles from
/// [origin], the board's top left corner, centred across the scene with
/// room on its left for the ship.
final class _BoardLayout {
  _BoardLayout(ArrivalStage s, BoardPlay play)
    : tile = s.u * 0.16,
      origin = Offset(
        s.box.center.dx -
            s.u * 0.16 * (play.level.width - BoardPlay.leftRoom) / 2,
        s.box.top + s.u * 0.4,
      );

  final double tile;
  final Offset origin;

  /// The point [x], [y] (in tiles) on the tilted board.
  Offset at(double x, double y) => origin + Offset(x * tile, y * tile * tilt);

  /// Where Koba's wheels touch tile [x], [y].
  Offset foot(double x, double y) =>
      at(x + 0.5, y + 0.5) + Offset(0, tile * 0.36);
}

/// One step of an arrival's run: a move or a turn of block [block].
typedef BoardStep = ({
  int block,
  GridPoint from,
  GridPoint to,
  double fromAngle,
  double toAngle,
  bool turn,
  bool star,
});

/// A [BoardArrival]'s puzzle, its picture and its run, built once.
final class BoardPlay {
  BoardPlay(BoardArrival scene)
    : level = Level.fromRows(
        id: 'arrival-${scene.concept}',
        concept: scene.concept,
        rows: scene.rows,
        startFacing: scene.facing,
        palette: {for (final b in scene.blocks) b.kind},
      ),
      theme = scene.theme {
    run = runProgram(
      compileBlocks([
        for (final (i, type) in scene.blocks.indexed)
          Block(id: '$i', type: type),
      ]),
      level,
    );
    var angle = level.startFacing.index * pi / 2;
    for (final event in run.events) {
      switch (event) {
        case Moved(:final from, :final to):
          steps.add((
            block: int.parse(event.blockId!),
            from: from,
            to: to,
            fromAngle: angle,
            toAngle: angle,
            turn: false,
            star: false,
          ));
        case Turned(:final from, :final to):
          final turn = (to.index - from.index + 4) % 4 == 1 ? pi / 2 : -pi / 2;
          final at = steps.isEmpty ? level.start : steps.last.to;
          steps.add((
            block: int.parse(event.blockId!),
            from: at,
            to: at,
            fromAngle: angle,
            toAngle: angle + turn,
            turn: true,
            star: false,
          ));
          angle += turn;
        case Collected():
          final last = steps.removeLast();
          steps.add((
            block: last.block,
            from: last.from,
            to: last.to,
            fromAngle: last.fromAngle,
            toAngle: last.toAngle,
            turn: last.turn,
            star: true,
          ));
        case Bumped() || PathChecked() || StepsStored():
          break;
      }
    }
  }

  /// Room left of the board for the ship, in tiles.
  static const leftRoom = 2.6;

  /// Where the finish's picture reaches, around its tile (as in the world).
  static const finishBounds = Rect.fromLTWH(-0.1, -0.1, 1.2, 1.2);

  final Level level;
  final WorldTheme theme;
  late final RunResult run;
  final steps = <BoardStep>[];

  late final board = BoardPainter(level, theme, leftRoom: leftRoom);
  late final Image finish = inkedPiece(
    (canvas) => drawFinish(canvas, theme.finish),
    bounds: finishBounds,
  );
}
