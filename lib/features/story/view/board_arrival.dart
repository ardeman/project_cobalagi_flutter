import 'dart:math';
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/core/character/robot_turn.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/grid_point.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_tile.dart';
import 'package:cobalagi/features/play/view/world/board_painter.dart';
import 'package:cobalagi/features/play/view/world/ink.dart';
import 'package:cobalagi/features/play/view/world/world_game.dart';
import 'package:cobalagi/features/play/view/world/world_theme.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/story_paint.dart';

/// A block of an arrival's program; [BoardPlay] gives every block its id.
Block arrivalBlock(
  BlockType type, {
  int count = 2,
  List<Block> children = const [],
  List<Block> otherwise = const [],
}) => Block(
  id: '',
  type: type,
  count: count,
  children: children,
  otherwise: otherwise,
);

/// Plain blocks, one of each type in turn.
List<Block> arrivalBlocks(List<BlockType> types) => [
  for (final type in types) arrivalBlock(type),
];

/// An arrival played on a small puzzle of the planet, drawn like its real
/// board: while the narrator sets the scene the ship lands beside it and
/// Koba rolls onto the start; in Koba's beat the puzzle's blocks drop into
/// a program row one after another (repeats and eye blocks holding theirs,
/// the Magic Block's own row below), Go is pressed, and Koba runs them tile
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
  List<Block> get program;

  /// The Magic Block's blocks, shown in a row of their own.
  List<Block> get magic => const [];

  /// A muddled program run first (Fix it!): it bumps, the block that bumped
  /// wears the orange ring and turns into [program]'s, and Koba goes back
  /// to the start and runs [program]. It must have [program]'s shape.
  List<Block>? get muddled => null;

  /// Obstacle tiles left as bare ground for [paintProps].
  Set<GridPoint> get bare => const {};

  /// The puzzle, its blocks and the run, built once.
  BoardPlay get play => _plays[concept] ??= BoardPlay(this);

  // Kept for the app's life: a few small pictures per planet.
  static final _plays = <String, BoardPlay>{};

  @override
  Duration get kobaLength => const Duration(milliseconds: 7000);

  /// Koba's beat: when the blocks drop in, when Go is pressed, and when the
  /// run plays (0 to 1).
  static const _dropsFrom = 0.03, _dropsTo = 0.28, _go = 0.3;
  static const _runFrom = 0.34;

  /// When in Koba's beat the run must be over at the latest.
  double get runTo => 0.92;

  /// How much of the beat a second of the run takes: as fast as in the
  /// puzzle, unless the run is too long to fit before [runTo].
  double get _perSecond => min(
    1000 / kobaLength.inMilliseconds,
    (runTo - _runFrom) / play.starts.last,
  );

  double _dropAt(int order) =>
      _dropsFrom +
      (_dropsTo - _dropsFrom) * order / max(1, play.blockCount - 1);

  /// When step [i] of the run starts (with [i] past the last, when the run
  /// ends), timed as in the puzzle.
  double stepAt(int i) => _runFrom + play.starts[i] * _perSecond;

  /// When in Koba's beat the run ends.
  double get runEnd => stepAt(play.steps.length);

  /// When the muddled block turns into the right one (Fix it!).
  double get _fixAt {
    final i = play.steps.indexWhere((s) => s.kind == BoardStepKind.fix);
    return i < 0 ? 0 : (stepAt(i) + stepAt(i + 1)) / 2;
  }

  /// The step playing at [t] (the last one once the run is over).
  int stepNow(double t) {
    var i = 0;
    while (i + 1 < play.steps.length && stepAt(i + 1) <= t) {
      i++;
    }
    return i;
  }

  /// How far through step [i] the run is at [t], 0 to 1, not eased.
  double _through(int i, double t) =>
      ((t - stepAt(i)) / (stepAt(i + 1) - stepAt(i))).clamp(0, 1);

  @override
  List<(double, SoundEffect)> get effects => [
    for (var i = 0; i < play.blockCount; i++)
      (_dropAt(i) + 0.03, SoundEffect.drop),
    for (final (i, step) in play.steps.indexed) ...[
      ?switch (step.kind) {
        BoardStepKind.move ||
        BoardStepKind.back => (stepAt(i), SoundEffect.step),
        BoardStepKind.turn => (stepAt(i), SoundEffect.turn),
        BoardStepKind.look => (stepAt(i), SoundEffect.poke),
        BoardStepKind.store => (stepAt(i), SoundEffect.drop),
        BoardStepKind.bump => (stepAt(i), theme.obstacle.bumpSound),
        BoardStepKind.fix => (_fixAt, SoundEffect.drop),
        BoardStepKind.go => null,
      },
      if (step.star) (stepAt(i + 1), SoundEffect.star),
    ],
    (runEnd, SoundEffect.goal),
  ];

  /// Paints things standing on the ground beside the board, behind the ship
  /// and Koba, with the block [running] (null before Go and after the run).
  void paintProps(ArrivalStage s, BoardLayout b, BlockType? running) {}

  /// Paints over everything, with where the run is in Koba's beat ([now],
  /// null while the ship lands).
  void paintOver(ArrivalStage s, BoardLayout b, BoardMoment? now) {}

  // Unused: the board scene paints itself.
  @override
  void paintPlanet(ArrivalStage s) {}

  @override
  void paintKobaBeat(ArrivalStage s) {}

  @override
  void paint(Canvas canvas, Rect stage, StoryFrame frame, StoryArt? art) =>
      _paint(ArrivalStage(canvas, stage, frame, art));

  @override
  void paintSplit(
    Canvas canvas,
    Rect stage,
    Rect controls,
    StoryFrame frame,
    StoryArt? art,
  ) => _paint(ArrivalStage(canvas, stage, frame, art, rows: controls));

  void _paint(ArrivalStage s) {
    final canvas = s.canvas;
    final frame = s.frame;
    final b = BoardLayout(s, play);
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
      paintProps(s, b, null);
      _paintStars(s, b, const {});
      _paintFinish(s, b);
      paintLanding(
        s,
        ship: ship,
        shipSize: shipSize,
        to: b.foot(play.level.start.x + 0.0, play.level.start.y + 0.0),
        kobaSize: kobaSize,
      );
      paintOver(s, b, null);
      return;
    }

    final now = _moment(s, b);
    paintProps(s, b, now.running?.type);
    paintLanded(s, ship: ship, shipSize: shipSize);
    _paintProgram(s, now);

    final step = now.step;
    final taken = {
      for (final (i, earlier) in play.steps.indexed)
        if (earlier.star && i > now.lastBack && (i < now.index || now.done))
          earlier.to,
    };
    // A star pops as Koba arrives on it.
    final popping = !now.done && step.star && now.through > 0.85
        ? step.to
        : null;
    // Things further up the board are painted first.
    final kobaFirst = now.y < play.level.goal.y;
    if (!kobaFirst) _paintFinish(s, b);
    _paintStars(s, b, taken, popping: popping, pop: now.through);
    if (now.running != null && step.kind == BoardStepKind.look) {
      _paintLook(s, b, now);
    }
    _paintKoba(
      s,
      b,
      now,
      size: kobaSize,
      face: now.done
          ? RobotFace.cheer
          : step.kind == BoardStepKind.bump ||
                (step.kind == BoardStepKind.fix && now.through < 0.5)
          ? RobotFace.dizzy
          : RobotFace.normal,
      rolling:
          !now.done &&
          s.t >= _runFrom &&
          (step.kind == BoardStepKind.move || step.kind == BoardStepKind.back),
    );
    if (kobaFirst) _paintFinish(s, b);
    paintOver(s, b, now);
  }

  /// Where the run is at the beat's time.
  BoardMoment _moment(ArrivalStage s, BoardLayout b) {
    final t = s.t;
    final done = t >= runEnd;
    final index = stepNow(t);
    final step = play.steps[index];
    final through = t < _runFrom ? 0.0 : (done ? 1.0 : _through(index, t));
    final p = step.curve.transform(through);
    var (x, y) = (
      storyLerp(step.from.x + 0.0, step.to.x + 0.0, p),
      storyLerp(step.from.y + 0.0, step.to.y + 0.0, p),
    );
    if (step.kind == BoardStepKind.bump) {
      // A nudge towards the obstacle and back.
      final nudge = 0.22 * sin(pi * through);
      x += (step.ahead.x - step.from.x) * nudge;
      y += (step.ahead.y - step.from.y) * nudge;
    }
    final running =
        !done && t >= _runFrom && step.block != null && step.kind.runsBlock
        ? play.byId[step.block]
        : null;
    var lastBack = -1;
    for (var i = 0; i <= index; i++) {
      if (play.steps[i].kind == BoardStepKind.back) lastBack = i;
    }
    return BoardMoment(
      index: index,
      step: step,
      through: through,
      done: done,
      x: x,
      y: y,
      angle: storyLerp(step.fromAngle, step.toAngle, p),
      foot: b.foot(x, y),
      running: running,
      lit: running == null
          ? const {}
          : {...play.withParents(step.block!), ...play.withParents(step.call)},
      lastBack: lastBack,
    );
  }

  /// The program shown at [t]: the muddled one until it is fixed.
  List<RowPiece> _rowAt(double t) =>
      play.muddledRow != null && t < _fixAt ? play.muddledRow! : play.row;

  /// How wide a block in the program row is: smaller when many blocks
  /// would not fit across the scene.
  double blockSize(ArrivalStage s) {
    final rows = s.rows;
    if (rows != null) {
      // In front of the fold: as big as the room allows, like the blocks
      // the child places there, but no bigger.
      return min(
        64,
        min(
          rows.width / (max(play.rowWidth + 1.22, play.magicWidth) + 1.2),
          rows.height / (_rowsHeight + 0.4),
        ),
      );
    }
    return min(
      s.u * 0.1,
      s.u * 1.3 / max(play.rowWidth + 1.22, play.magicWidth),
    );
  }

  /// The program rows' height, in blocks.
  double get _rowsHeight =>
      play.rowHeight + (play.magicRow.isEmpty ? 0 : 0.3 + play.magicHeight);

  /// The middle of the program row's height.
  double _rowY(ArrivalStage s, double size) {
    final rows = s.rows;
    if (rows == null) return s.box.top + s.u * 0.15;
    return rows.center.dy - _rowsHeight * size / 2 + play.rowHeight * size / 2;
  }

  /// The middle of where the rows go, across.
  double _rowsX(ArrivalStage s) => (s.rows ?? s.box).center.dx;

  /// Where block [id] is in the program rows at [ArrivalStage.t], if shown.
  Rect? blockRect(ArrivalStage s, String id) {
    for (final (piece, rect) in _placed(s)) {
      if (!piece.frame && piece.block.id == id) return rect;
    }
    return null;
  }

  /// Every piece of the program rows with where it is painted.
  Iterable<(RowPiece, Rect)> _placed(ArrivalStage s) sync* {
    final size = blockSize(s);
    final width = play.rowWidth + 1.22;
    final left = _rowsX(s) - width * size / 2;
    final y = _rowY(s, size);
    for (final piece in _rowAt(s.t)) {
      yield (piece, _scaled(piece.rect, Offset(left, y), size));
    }
    if (play.magicRow.isEmpty) return;
    final magicY = y + size * (play.rowHeight / 2 + 0.3 + play.magicHeight / 2);
    final magicLeft = _rowsX(s) - play.magicWidth * size / 2;
    for (final piece in play.magicRow) {
      yield (piece, _scaled(piece.rect, Offset(magicLeft, magicY), size));
    }
  }

  static Rect _scaled(Rect r, Offset origin, double size) => Rect.fromLTRB(
    r.left * size,
    r.top * size,
    r.right * size,
    r.bottom * size,
  ).shift(origin);

  /// Where Go is.
  Offset _goAt(ArrivalStage s) {
    final size = blockSize(s);
    final width = play.rowWidth + 1.22;
    return Offset(_rowsX(s) + width * size / 2 - size / 2, _rowY(s, size));
  }

  /// The program rows over the board: each block drops into its place, then
  /// Go is pressed and the block running glows (and the repeat, eye or
  /// Magic Block it runs in).
  void _paintProgram(ArrivalStage s, BoardMoment now) {
    final canvas = s.canvas;
    final size = blockSize(s);
    final show = Curves.easeOut.transform((s.t / 0.05).clamp(0, 1));
    final pieces = _placed(s).toList();
    // A glass tray under each row.
    for (final tray in _trays(s, pieces, size)) {
      final rect = RRect.fromRectAndRadius(tray, Radius.circular(size * 0.36));
      canvas
        ..drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.16 * show),
        )
        ..drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45 * show)
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.5, s.u * 0.004),
        );
    }
    final bump = play.steps.indexWhere((s) => s.kind == BoardStepKind.bump);
    final ringed = bump >= 0 && s.t >= stepAt(bump) && s.t < _fixAt
        ? play.steps[bump].block
        : null;
    final flip = (s.t - _fixAt) / 0.05;
    for (final (piece, rect) in pieces) {
      final drop = ((s.t - _dropAt(piece.order)) / 0.04).clamp(0.0, 1.0);
      if (drop == 0) continue;
      final fall = Curves.easeOutBack.transform(drop);
      final at = rect.shift(Offset(0, -(1 - fall) * s.u * 0.08));
      final lit = now.lit.contains(piece.block.id);
      if (piece.frame) {
        _paintFrame(canvas, piece, at, size, lit: lit);
        continue;
      }
      // The fixed block pops in its place.
      final fixed = flip > 0 && flip < 1 && piece.block.id == play.fixedId
          ? 1 + 0.25 * sin(pi * flip)
          : 1.0;
      paintBlock(canvas, piece.block.type, at.center, size * fixed, glow: lit);
      if (piece.block.type == BlockType.repeat ||
          piece.block.type == BlockType.setSteps) {
        _paintCount(canvas, at, piece.block.count, size);
      }
      if (piece.block.id == ringed) _paintRing(canvas, at, size);
    }
    // Go, pressed once every block is in, and again after a fix.
    final presses = [
      _go,
      for (final (i, step) in play.steps.indexed)
        if (step.kind == BoardStepKind.go) stepAt(i),
    ];
    final press = presses
        .map((at) => ((s.t - at) / 0.04).clamp(0.0, 1.0))
        .firstWhere((p) => p > 0 && p < 1, orElse: () => 0);
    final c = _goAt(s);
    final r = size * 0.5 * (1 - 0.15 * sin(pi * press));
    if (press > 0) {
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

  /// The trays behind the program row (with Go) and the Magic Block's row.
  Iterable<Rect> _trays(
    ArrivalStage s,
    List<(RowPiece, Rect)> pieces,
    double size,
  ) sync* {
    final gap = size * 0.22;
    final go = _goAt(s);
    final main = Rect.fromLTRB(
      go.dx - (play.rowWidth + 1.22) * size,
      go.dy - size * play.rowHeight / 2,
      go.dx + size / 2,
      go.dy + size * play.rowHeight / 2,
    );
    yield main.inflate(gap);
    if (play.magicRow.isEmpty) return;
    yield pieces
        .where((p) => play.magicRow.contains(p.$1))
        .map((p) => p.$2)
        .reduce((a, b) => a.expandToInclude(b))
        .inflate(gap);
  }

  /// A container's frame: a light box in its colour around its blocks, with
  /// a dashed line between an eye block's two rows.
  void _paintFrame(
    Canvas canvas,
    RowPiece piece,
    Rect at,
    double size, {
    required bool lit,
  }) {
    final color = piece.block.type.color;
    final rect = RRect.fromRectAndRadius(at, Radius.circular(size * 0.3));
    if (lit) {
      canvas.drawRRect(
        rect.inflate(size * 0.06),
        Paint()
          ..color = storyGold.withValues(alpha: 0.7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.1),
      );
    }
    canvas
      ..drawRRect(
        rect,
        Paint()..color = Color.lerp(color, const Color(0xFFFFFFFF), 0.6)!,
      )
      ..drawRRect(
        rect,
        Paint()
          ..color = storyInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, size * 0.05),
      );
    final divider = piece.divider;
    if (divider == null) return;
    final x = at.left + divider * size;
    final paint = Paint()
      ..color = color
      ..strokeWidth = size * 0.06
      ..strokeCap = StrokeCap.round;
    for (
      var y = at.top + size * 0.2;
      y < at.bottom - size * 0.2;
      y += size * 0.2
    ) {
      canvas.drawLine(Offset(x, y), Offset(x, y + size * 0.08), paint);
    }
  }

  /// A block's number in a white badge on its corner.
  void _paintCount(Canvas canvas, Rect at, int count, double size) {
    final c = at.bottomRight - Offset(size * 0.1, size * 0.1);
    final r = size * 0.24;
    canvas
      ..drawCircle(c, r, Paint()..color = const Color(0xFFFFFFFF))
      ..drawCircle(
        c,
        r,
        Paint()
          ..color = storyInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, size * 0.04),
      );
    _paintText(canvas, '$count', c, size * 0.32);
  }

  /// The bump's mark: a crisp orange ring outside a white gap, with "!".
  void _paintRing(Canvas canvas, Rect at, double size) {
    final rect = RRect.fromRectAndRadius(at, Radius.circular(size * 0.22));
    canvas
      ..drawRRect(
        rect.inflate(size * 0.06),
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.07,
      )
      ..drawRRect(
        rect.inflate(size * 0.12),
        Paint()
          ..color = bumpOrange
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.07,
      );
    final c = at.topRight + Offset(-size * 0.02, size * 0.02);
    canvas.drawCircle(c, size * 0.2, Paint()..color = bumpOrange);
    _paintText(canvas, '!', c, size * 0.3, color: const Color(0xFFFFFFFF));
  }

  /// Koba's headlight on the tile ahead while an eye block looks, warm when
  /// the way is clear and orange when it isn't.
  void _paintLook(ArrivalStage s, BoardLayout b, BoardMoment now) {
    final step = now.step;
    final light = sin(pi * now.through);
    final ahead = b.at(step.ahead.x + 0.5, step.ahead.y + 0.5);
    final from = now.foot - Offset(0, b.tile * 0.45);
    final side = Offset(-(ahead - from).dy, (ahead - from).dx);
    final spread = side / max(1, side.distance) * b.tile * 0.4;
    final color = step.clear ? storyGold : bumpOrange;
    s.canvas
      ..drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo((ahead + spread).dx, (ahead + spread).dy)
          ..lineTo((ahead - spread).dx, (ahead - spread).dy)
          ..close(),
        Paint()
          ..color = color.withValues(alpha: 0.35 * light)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.tile * 0.06),
      )
      ..drawOval(
        Rect.fromCenter(
          center: ahead,
          width: b.tile * 0.8,
          height: b.tile * 0.8 * tilt,
        ),
        Paint()
          ..color = color.withValues(alpha: 0.5 * light)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.tile * 0.1),
      );
  }

  /// The stars still on the board ([taken] ones gone), the one [popping]
  /// growing and fading as Koba takes it, [pop] through its step.
  void _paintStars(
    ArrivalStage s,
    BoardLayout b,
    Set<GridPoint> taken, {
    GridPoint? popping,
    double pop = 0,
  }) {
    for (final star in play.level.stars) {
      if (taken.contains(star)) continue;
      final p = star == popping ? (pop - 0.85) / 0.15 : 0.0;
      paintStoryStar(
        s.canvas,
        b.at(star.x + 0.5, star.y + 0.5) -
            Offset(
              0,
              b.tile * (0.12 + 0.03 * sin(s.time * 3 + star.x) + p * 0.3),
            ),
        b.tile * 0.3 * (1 + 0.5 * p),
        opacity: 1 - p.clamp(0, 1),
        turn: s.time + star.x,
      );
    }
  }

  /// The finish on its tile, standing up as in the world.
  void _paintFinish(ArrivalStage s, BoardLayout b) {
    final goal = play.level.goal;
    final pulse = 1 + 0.04 * sin(s.time * 4);
    final at = b.at(goal.x + 0.5, goal.y + 0.82);
    s.canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..scale(b.tile * pulse)
      ..translate(-0.5, -0.82);
    drawInked(s.canvas, play.finish, BoardPlay.finishBounds);
    s.canvas.restore();
  }

  /// Koba where the run is, shown as in the world: its back going up, its
  /// front coming down, its side across, and the 3D robot's frames as it
  /// turns between them.
  void _paintKoba(
    ArrivalStage s,
    BoardLayout b,
    BoardMoment now, {
    required double size,
    required RobotFace face,
    required bool rolling,
  }) {
    if (s.art == null) return;
    final foot = now.foot;
    s.canvas.drawOval(
      Rect.fromCenter(
        center: foot,
        width: b.tile * 0.64,
        height: b.tile * 0.16,
      ),
      Paint()..color = const Color(0x40000000),
    );
    final facing = Direction.values[(now.angle / (pi / 2)).round() % 4];
    final cheer = face == RobotFace.cheer;
    s.koba(
      foot - Offset(0, rolling ? 0 : sin(s.time * 2.4).abs() * b.tile * 0.02),
      size: size,
      face: face,
      back: facing == Direction.north && !cheer,
      front: facing == Direction.south,
      mirror: facing == Direction.west,
      turnFrame: robotTurnFrame(now.angle),
    );
  }
}

/// The bump's orange, as on the coding screen.
const bumpOrange = Color(0xFFFF8A00);

/// [text] in bold ink, centred on [c].
void _paintText(
  Canvas canvas,
  String text,
  Offset c,
  double size, {
  Color color = storyInk,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, c - Offset(painter.width / 2, painter.height / 2));
  painter.dispose();
}

/// Where a [BoardArrival]'s run is at one moment of Koba's beat.
final class BoardMoment {
  const BoardMoment({
    required this.index,
    required this.step,
    required this.through,
    required this.done,
    required this.x,
    required this.y,
    required this.angle,
    required this.foot,
    required this.running,
    required this.lit,
    required this.lastBack,
  });

  /// The step playing, and how far through it (0 to 1).
  final int index;
  final BoardStep step;
  final double through;

  /// Whether the run is over.
  final bool done;

  /// Koba on the board, in tiles, facing [angle] (clockwise from up the
  /// board), its wheels at [foot].
  final double x, y, angle;
  final Offset foot;

  /// The block running, and the ids lit with it (its containers, and the
  /// Magic Block running it).
  final Block? running;
  final Set<String> lit;

  /// The last step that took Koba back to the start, or -1.
  final int lastBack;
}

/// Where a [BoardArrival]'s board lies in the scene: [tile] wide tiles from
/// [origin], the board's top left corner, centred across the scene with
/// room on its left for the ship (smaller for a long board), and lower
/// when a Magic Block row sits above it.
final class BoardLayout {
  factory BoardLayout(ArrivalStage s, BoardPlay play) {
    final across = play.level.width + BoardPlay.leftRoom;
    final tile = min(s.u * 0.16, s.u * 1.3 / across);
    return BoardLayout._(
      tile,
      Offset(
        s.box.center.dx - tile * (play.level.width - BoardPlay.leftRoom) / 2,
        s.box.top +
            s.u *
                (s.rows != null
                    ? 0.25
                    : play.magicRow.isEmpty
                    ? 0.4
                    : 0.47),
      ),
    );
  }

  BoardLayout._(this.tile, this.origin);

  final double tile;
  final Offset origin;

  /// The point [x], [y] (in tiles) on the tilted board.
  Offset at(double x, double y) => origin + Offset(x * tile, y * tile * tilt);

  /// Where Koba's wheels touch tile [x], [y].
  Offset foot(double x, double y) =>
      at(x + 0.5, y + 0.5) + Offset(0, tile * 0.36);
}

/// What a step of an arrival's run shows.
enum BoardStepKind {
  /// A move or a turn.
  move,
  turn,

  /// An eye block looks at the tile ahead.
  look,

  /// A Step Box block stores its number.
  store,

  /// Koba bumps into an obstacle.
  bump,

  /// The bumped block turns into the right one (Fix it!).
  fix,

  /// Koba goes back to the start.
  back,

  /// Go is pressed again.
  go;

  /// Whether a block runs in this step, lit in the program row.
  bool get runsBlock => index <= bump.index;
}

/// One step of an arrival's run.
final class BoardStep {
  BoardStep(
    this.kind, {
    required this.from,
    required this.angle,
    this.block,
    GridPoint? to,
    double? toAngle,
    GridPoint? ahead,
    this.clear = true,
    this.value = 0,
  }) : to = to ?? from,
       toAngle = toAngle ?? angle,
       ahead = ahead ?? from;

  final BoardStepKind kind;

  /// The block running, if any.
  final String? block;

  /// The Magic Block in the program running [block], if any.
  String? call;

  /// Where Koba goes from and to, and its angle (clockwise from up the
  /// board) at the start and end.
  final GridPoint from, to;
  final double angle, toAngle;
  double get fromAngle => angle;

  /// The tile an eye block looks at or Koba bumps into, whether the way
  /// was clear, and the number a Step Box stored.
  final GridPoint ahead;
  final bool clear;
  final int value;

  /// Whether Koba takes a star at the end.
  bool star = false;
  Curve curve = Curves.linear;
}

/// A block (or a container's frame, behind its blocks) laid in a program
/// row, in units of a block's width from the row's left end and its middle.
final class RowPiece {
  RowPiece(
    this.block,
    this.rect,
    this.order, {
    this.frame = false,
    this.divider,
  });

  final Block block;
  final Rect rect;

  /// When it drops in, among all the blocks.
  final int order;
  final bool frame;

  /// Where an eye block's second row starts, from the frame's left.
  final double? divider;
}

/// A [BoardArrival]'s puzzle, its picture, its program rows and its run,
/// built once.
final class BoardPlay {
  BoardPlay(BoardArrival scene)
    : theme = scene.theme,
      bare = scene.bare,
      level = Level.fromRows(
        id: 'arrival-${scene.concept}',
        concept: scene.concept,
        rows: scene.rows,
        startFacing: scene.facing,
        palette: {BlockType.forward.kind},
      ) {
    final program = _numbered(scene.program, 'm');
    final magic = _numbered(scene.magic, 's');
    final muddled = scene.muddled == null
        ? null
        : _numbered(scene.muddled!, 'm');
    var order = 0;
    final (pieces, width, height) = _layRow(program, () => order++);
    row = pieces;
    rowWidth = width;
    rowHeight = height;
    if (magic.isNotEmpty) {
      final holder = Block(id: 'magic', type: BlockType.star, children: magic);
      final (pieces, width, height) = _layRow([holder], () => order++);
      magicRow = pieces;
      magicWidth = width;
      magicHeight = height;
    }
    blockCount = order;
    if (muddled != null) {
      var again = 0;
      muddledRow = _layRow(muddled, () => again++).$1;
      fixedId = _flatten(muddled)
          .firstWhere(
            (b) =>
                _flatten(program).any((p) => p.id == b.id && p.type != b.type),
          )
          .id;
    }
    for (final block in [..._flatten(program), ..._flatten(magic)]) {
      byId[block.id] = block;
    }
    for (final block in _flatten(muddled ?? const [])) {
      byId.putIfAbsent(block.id, () => block);
    }
    _parentsOf(program, null);
    _parentsOf(magic, 'magic');
    _parentsOf(muddled ?? const [], null);
    _magicIds = {for (final b in _flatten(magic)) b.id};
    _calls = [
      for (final b in _flatten(program))
        if (b.type == BlockType.star) b.id,
    ];

    var angle = level.startFacing.index * pi / 2;
    if (muddled != null) {
      angle = _addRun(
        runProgram(compileBlocks(muddled, star: magic), level),
        angle,
      );
      final at = steps.last.to;
      final bumped = steps.lastWhere((s) => s.kind == BoardStepKind.bump);
      steps.add(
        BoardStep(
          BoardStepKind.fix,
          from: at,
          angle: angle,
          block: bumped.block,
        ),
      );
      // Back to the start, turning the shorter way to face as at first.
      final start = level.startFacing.index * pi / 2;
      final back = angle + ((start - angle + pi) % (2 * pi) - pi);
      steps
        ..add(
          BoardStep(
            BoardStepKind.back,
            from: at,
            to: level.start,
            angle: angle,
            toAngle: back,
          ),
        )
        ..add(BoardStep(BoardStepKind.go, from: level.start, angle: back));
      angle = back;
    }
    run = runProgram(compileBlocks(program, star: magic), level);
    _addRun(run, angle);
    _timeSteps();
  }

  /// Room left of the board for the ship, in tiles.
  static const leftRoom = 2.6;

  /// Where the finish's picture reaches, around its tile (as in the world).
  static const finishBounds = Rect.fromLTWH(-0.1, -0.1, 1.2, 1.2);

  final Level level;
  final WorldTheme theme;
  final Set<GridPoint> bare;

  /// The run of the program (after the muddled one's, for Fix it!).
  late final RunResult run;
  final steps = <BoardStep>[];

  /// When each step starts, in seconds from the first, and last when the
  /// run ends.
  final starts = <double>[0];

  /// The program row, its width (without Go) and height, in blocks.
  late final List<RowPiece> row;
  late final double rowWidth, rowHeight;

  /// The Magic Block's row, if it has blocks.
  List<RowPiece> magicRow = const [];
  double magicWidth = 0, magicHeight = 0;

  /// The muddled program's row, and the id of the block fixed in it.
  List<RowPiece>? muddledRow;
  String? fixedId;

  /// How many blocks drop in.
  late final int blockCount;

  /// Every block by its id.
  final byId = <String, Block>{};
  final _parents = <String, String>{};
  late final Set<String> _magicIds;
  late final List<String> _calls;

  late final board = BoardPainter(level, theme, leftRoom: leftRoom, bare: bare);
  late final Image finish = inkedPiece(
    (canvas) => drawFinish(canvas, theme.finish),
    bounds: finishBounds,
  );

  /// Block [id] and the containers it sits in, outermost last.
  Set<String> withParents(String? id) => {
    for (String? at = id; at != null; at = _parents[at]) at,
  };

  void _parentsOf(List<Block> blocks, String? parent) {
    for (final block in blocks) {
      if (parent != null) _parents[block.id] = parent;
      _parentsOf([...block.children, ...block.otherwise], block.id);
    }
  }

  /// Adds the steps of [run], with Koba starting at [angle]; returns the
  /// angle it ends at.
  double _addRun(RunResult run, double startAngle) {
    var angle = startAngle;
    GridPoint at() => steps.isEmpty || steps.last.kind == BoardStepKind.go
        ? level.start
        : steps.last.to;
    for (final event in run.events) {
      final id = event.blockId;
      switch (event) {
        case Moved(:final from, :final to):
          steps.add(
            BoardStep(
              BoardStepKind.move,
              from: from,
              to: to,
              angle: angle,
              block: id,
            ),
          );
        case Turned(:final from, :final to):
          final turn = (to.index - from.index + 4) % 4 == 1 ? pi / 2 : -pi / 2;
          steps.add(
            BoardStep(
              BoardStepKind.turn,
              from: at(),
              angle: angle,
              toAngle: angle + turn,
              block: id,
            ),
          );
          angle += turn;
        case Collected():
          steps.last.star = true;
        case PathChecked(:final ahead, :final clear):
          steps.add(
            BoardStep(
              BoardStepKind.look,
              from: at(),
              angle: angle,
              ahead: ahead,
              clear: clear,
              block: id,
            ),
          );
        case StepsStored(:final value):
          steps.add(
            BoardStep(
              BoardStepKind.store,
              from: at(),
              angle: angle,
              value: value,
              block: id,
            ),
          );
        case Bumped(:final at):
          steps.add(
            BoardStep(
              BoardStepKind.bump,
              from: at,
              angle: angle,
              ahead: at.step(Direction.values[(angle / (pi / 2)).round() % 4]),
              block: id,
            ),
          );
      }
    }
    return angle;
  }

  /// Times the steps as in the puzzle (steps in a row roll on, turns turn),
  /// and finds the Magic Block in the program running each of its blocks:
  /// a new call starts when its blocks start again from an earlier one.
  void _timeSteps() {
    final order = [..._magicIds];
    var call = -1;
    for (final (i, step) in steps.indexed) {
      bool moves(int j) =>
          j >= 0 && j < steps.length && steps[j].kind == BoardStepKind.move;
      final (seconds, curve) = switch (step.kind) {
        BoardStepKind.move => WorldGame.moveTiming(
          rollIn: moves(i - 1),
          rollOn: moves(i + 1),
        ),
        BoardStepKind.turn => (WorldGame.turnTime, Curves.easeInOut),
        BoardStepKind.look => (0.5, Curves.linear),
        BoardStepKind.store => (0.6, Curves.linear),
        BoardStepKind.bump => (0.6, Curves.linear),
        BoardStepKind.fix => (1.4, Curves.linear),
        BoardStepKind.back => (0.9, Curves.easeInOut),
        BoardStepKind.go => (0.4, Curves.linear),
      };
      step.curve = curve;
      starts.add(starts.last + seconds);
      final block = step.block;
      if (block != null && _magicIds.contains(block) && _calls.isNotEmpty) {
        final before = i > 0 ? steps[i - 1].block : null;
        if (before == null ||
            !_magicIds.contains(before) ||
            order.indexOf(block) < order.indexOf(before)) {
          call++;
        }
        step.call = _calls[min(call, _calls.length - 1)];
      } else if (step.kind == BoardStepKind.back) {
        call = -1;
      }
    }
  }

  /// [blocks] with ids [prefix]0, [prefix]1… in the order they drop in.
  static List<Block> _numbered(List<Block> blocks, String prefix) {
    var next = 0;
    Block number(Block b) => Block(
      id: '$prefix${next++}',
      type: b.type,
      count: b.count,
      children: [for (final c in b.children) number(c)],
      otherwise: [for (final c in b.otherwise) number(c)],
    );
    return [for (final b in blocks) number(b)];
  }

  static Iterable<Block> _flatten(List<Block> blocks) =>
      blocks.expand((b) => b.selfAndDescendants);

  static const _gap = 0.22, _pad = 0.16;

  static double _height(Block b) => b.children.isEmpty && !b.type.isContainer
      ? 1
      : [
              1.0,
              for (final c in [...b.children, ...b.otherwise]) _height(c),
            ].reduce(max) +
            2 * _pad;

  /// Lays [blocks] in a row; returns its pieces, width and height.
  static (List<RowPiece>, double, double) _layRow(
    List<Block> blocks,
    int Function() order,
  ) {
    final pieces = <RowPiece>[];
    double lay(Block b, double x) {
      if (b.children.isEmpty && !b.type.isContainer) {
        pieces.add(RowPiece(b, Rect.fromLTWH(x, -0.5, 1, 1), order()));
        return x + 1;
      }
      final h = _height(b);
      final frameAt = pieces.length;
      final header = RowPiece(b, Rect.fromLTWH(x + _pad, -0.5, 1, 1), order());
      var cx = x + _pad + 1 + _gap;
      for (final c in b.children) {
        cx = lay(c, cx) + _gap;
      }
      double? divider;
      if (b.type == BlockType.ifElse) {
        divider = cx + _gap / 2 - x;
        cx += _gap * 2;
        for (final c in b.otherwise) {
          cx = lay(c, cx) + _gap;
        }
      }
      final end = cx - _gap + _pad;
      pieces
        ..insert(
          frameAt,
          RowPiece(
            b,
            Rect.fromLTRB(x, -h / 2, end, h / 2),
            header.order,
            frame: true,
            divider: divider,
          ),
        )
        ..insert(frameAt + 1, header);
      return end;
    }

    var x = 0.0;
    for (final b in blocks) {
      x = lay(b, x) + _gap;
    }
    return (
      pieces,
      max(0, x - _gap),
      [1.0, for (final b in blocks) _height(b)].reduce(max),
    );
  }
}
