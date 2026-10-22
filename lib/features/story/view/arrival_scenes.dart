import 'dart:math';

import 'package:flutter/animation.dart';

import 'package:flutter/painting.dart';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/grid_point.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_tile.dart';
import 'package:cobalagi/features/play/view/world/world_theme.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/board_arrival.dart';
import 'package:cobalagi/features/story/view/star_ship.dart';
import 'package:cobalagi/features/story/view/story_paint.dart';
import 'package:cobalagi/learning/story.dart';

/// The arrival scenes by planet (concept id).
const arrivalScenes = <String, ArrivalScene>{
  'directions': DirectionsArrival(),
  'sequencing': SequencingArrival(),
  'loops': LoopsArrival(),
  'functions': FunctionsArrival(),
  'conditions': ConditionsArrival(),
  'variables': VariablesArrival(),
  'debugging': DebuggingArrival(),
  'until': UntilArrival(),
  'otherwise': OtherwiseArrival(),
};

/// A planet's arrival (about 10 seconds), played on the first visit before
/// its "Watch me!" demo: the ship lands on the planet and Koba rolls out
/// while the narrator sets the scene, then Koba shows why it needs the
/// planet's skill.
abstract class ArrivalScene extends StoryScene {
  const ArrivalScene(this.concept);

  /// The planet's concept id.
  final String concept;

  @override
  String get id => Story.arrival(concept);

  WorldTheme get theme => WorldTheme.forConcept(concept);

  /// The narrator's line, then Koba's.
  String sceneWords(AppLocalizations l10n);
  String kobaWords(AppLocalizations l10n);

  /// Koba's thanks for the planet's skill, in the "tank full again" ending
  /// when this planet is the newest.
  String thanksWords(AppLocalizations l10n);

  /// Sounds in Koba's beat, by when (0 to 1).
  List<(double, SoundEffect)> get effects => const [];

  /// How long Koba's beat's pictures take.
  Duration get kobaLength => const Duration(milliseconds: 5500);

  @override
  List<StoryBeat> get beats => [
    StoryBeat(
      clip: VoiceClips.storyArrival(concept),
      words: sceneWords,
      length: const Duration(milliseconds: 4500),
      // Touches down when [paintLanding] lands it.
      effects: const [(0.43, SoundEffect.shipLand)],
    ),
    StoryBeat(
      clip: VoiceClips.storyArrivalKoba(concept),
      words: kobaWords,
      length: kobaLength,
      effects: effects,
    ),
  ];

  /// What is on the planet, painted behind the ship and Koba.
  void paintPlanet(ArrivalStage s);

  /// Koba's beat: Koba (from where it stopped, [ArrivalStage.kobaAt]) and
  /// anything over it.
  void paintKobaBeat(ArrivalStage s);

  /// Painted over everything in both beats (the fog).
  void paintFront(ArrivalStage s) {}

  @override
  void paint(Canvas canvas, Rect stage, StoryFrame frame, StoryArt? art) {
    final s = ArrivalStage(canvas, stage, frame, art);
    paintGround(canvas, s.box, s.ground, theme: theme);
    paintPlanet(s);
    final ship = s.on(0.14);
    if (frame.beat == 0) {
      paintLanding(s, ship: ship, shipSize: s.shipSize, to: s.kobaAt);
    } else {
      paintLanded(s, ship: ship, shipSize: s.shipSize);
      paintKobaBeat(s);
    }
    paintFront(s);
  }

  /// The scene's first beat: the ship comes down at [ship], [shipSize]
  /// wide, beside the planet's puzzle, and Koba ([kobaSize] wide) rolls out
  /// to [to].
  void paintLanding(
    ArrivalStage s, {
    required Offset ship,
    required double shipSize,
    required Offset to,
    double? kobaSize,
  }) {
    final art = s.art;
    final t = s.t;
    final down = Curves.easeOut.transform((t / 0.45).clamp(0, 1));
    final landed = t >= 0.45;
    final base = Offset(
      ship.dx,
      storyLerp(s.box.top - s.u * 0.2, ship.dy, down),
    );
    if (landed) paintDust(s.canvas, base, s.u, ((t - 0.45) / 0.3).clamp(0, 1));
    final out = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
    if (art == null) return;
    paintShip(
      s.canvas,
      art,
      landed ? ShipView.landed : ShipView.landing,
      base: base,
      size: shipSize,
      koba: out == 0,
      time: s.time,
    );
    if (out > 0) {
      s.koba(
        Offset(
          storyLerp(ship.dx, to.dx, Curves.easeOut.transform(out)),
          storyLerp(ship.dy, to.dy, Curves.easeOut.transform(out)),
        ),
        size: kobaSize,
        angle: out < 1 ? 0.05 * sin(s.time * 14) : 0,
      );
    }
  }

  /// The ship standing landed at [ship], after the first beat.
  void paintLanded(
    ArrivalStage s, {
    required Offset ship,
    required double shipSize,
  }) {
    final art = s.art;
    if (art == null) return;
    paintShip(
      s.canvas,
      art,
      ShipView.landed,
      base: ship,
      size: shipSize,
      koba: false,
      time: s.time,
    );
  }
}

/// Where an arrival scene paints: its box, unit and ground, and Koba.
final class ArrivalStage {
  factory ArrivalStage(
    Canvas canvas,
    Rect stage,
    StoryFrame frame,
    StoryArt? art, {
    Rect? rows,
  }) {
    final (box, u) = storyBox(stage);
    return ArrivalStage._(canvas, box, u, frame, art, rows);
  }

  ArrivalStage._(
    this.canvas,
    this.box,
    this.u,
    this.frame,
    this.art,
    this.rows,
  );

  /// Half folded, where program rows go (in front of the fold); null when
  /// they go over the board.
  final Rect? rows;

  final Canvas canvas;
  final Rect box;
  final double u;
  final StoryFrame frame;
  final StoryArt? art;

  double get t => frame.t;
  double get time => frame.time;
  double get ground => y(0.9);
  double get shipSize => u * 0.7;
  double get kobaSize => u * 0.42;

  /// Where Koba stops after rolling out of the ship.
  Offset get kobaAt => on(0.36);

  /// Where things stand at [fx] across the box: on the planet's flat
  /// piece, at [ground].
  Offset on(double fx) => Offset(x(fx), ground);

  double x(double fraction) => box.left + fraction * box.width;
  double y(double fraction) => box.top + fraction * box.height;
  Offset at(double fx, double fy) => Offset(x(fx), y(fy));

  /// Koba standing at [base] (by default where it stopped), from the side.
  void koba(
    Offset base, {
    RobotFace face = RobotFace.normal,
    double? size,
    bool front = false,
    bool back = false,
    bool mirror = false,
    double angle = 0,
    Offset gaze = Offset.zero,
    int? turnFrame,
  }) {
    final art = this.art;
    if (art == null) return;
    paintKoba(
      canvas,
      art,
      base: base,
      size: size ?? kobaSize,
      face: face,
      time: time,
      front: front,
      back: back,
      mirror: mirror,
      angle: angle,
      gaze: gaze,
      turnFrame: turnFrame,
    );
  }
}

/// Directions: Koba runs forward, left and right blocks along a path that
/// bends both ways, past signposts whose arrows, in the colours of the arrow
/// blocks, point every way and light up with the block running.
class DirectionsArrival extends BoardArrival {
  const DirectionsArrival() : super('directions');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalDirections;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalDirectionsKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksDirections;

  @override
  List<String> get rows => const ['#.*G#', '#.###', 'S.###'];

  @override
  Direction get facing => Direction.east;

  @override
  List<Block> get program => arrivalBlocks(const [
    BlockType.forward,
    BlockType.turnLeft,
    BlockType.forward,
    BlockType.forward,
    BlockType.turnRight,
    BlockType.forward,
    BlockType.forward,
  ]);

  @override
  Set<GridPoint> get bare => {
    const GridPoint(0, 0),
    const GridPoint(4, 1),
    const GridPoint(4, 2),
  };

  @override
  void paintProps(ArrivalStage s, BoardLayout b, BlockType? running) {
    // While the ship lands the arrows light in turn, pointing every way;
    // in the run, the one of the block running.
    final lit = s.frame.beat == 0
        ? const [
            BlockType.turnRight,
            BlockType.turnLeft,
            BlockType.forward,
          ][(s.time * 1.5).floor() % 3]
        : running;
    _signpost(s, b.at(0.5, 0.62), b.tile * 1.5, lit);
    _signpost(s, b.at(4.4, 2.7), b.tile * 1.9, lit);
  }

  /// A signpost standing at [foot], [k] tall in its own units, with arrows
  /// forward, right and left, the one for [lit] glowing.
  void _signpost(ArrivalStage s, Offset foot, double k, BlockType? lit) {
    final top = foot.dy - k * 0.62;
    s.canvas
      ..drawLine(
        foot,
        Offset(foot.dx, top),
        Paint()
          ..color = storyInk
          ..strokeWidth = k * 0.035
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        foot,
        Offset(foot.dx, top),
        Paint()
          ..color = const Color(0xFFB98A5E)
          ..strokeWidth = k * 0.022
          ..strokeCap = StrokeCap.round,
      );
    for (final (dy, side, type) in const [
      (0.0, 0, BlockType.forward),
      (0.2, 1, BlockType.turnRight),
      (0.33, -1, BlockType.turnLeft),
    ]) {
      _signArrow(
        s,
        Offset(foot.dx, top + k * dy),
        k,
        side,
        type.color,
        lit == type,
      );
    }
  }

  /// A board on the post at [at] pointing [side]ways (1 right, -1 left) or,
  /// with 0, up (forward), glowing when [lit]; [k] sizes it.
  void _signArrow(
    ArrivalStage s,
    Offset at,
    double k,
    int side,
    Color color,
    bool lit,
  ) {
    final h = k * 0.1;
    final w = k * 0.24;
    final path = Path();
    if (side == 0) {
      // Points up from the top of the post.
      path
        ..moveTo(at.dx - h / 2, at.dy)
        ..lineTo(at.dx - h / 2, at.dy - w * 0.5)
        ..lineTo(at.dx - h * 0.9, at.dy - w * 0.5)
        ..lineTo(at.dx, at.dy - w * 0.85)
        ..lineTo(at.dx + h * 0.9, at.dy - w * 0.5)
        ..lineTo(at.dx + h / 2, at.dy - w * 0.5)
        ..lineTo(at.dx + h / 2, at.dy)
        ..close();
    } else {
      final back = at.dx - side * h * 0.3;
      final head = at.dx + side * w * 0.7;
      final tip = at.dx + side * w;
      path
        ..moveTo(back, at.dy - h / 2)
        ..lineTo(head, at.dy - h / 2)
        ..lineTo(head, at.dy - h * 0.85)
        ..lineTo(tip, at.dy)
        ..lineTo(head, at.dy + h * 0.85)
        ..lineTo(head, at.dy + h / 2)
        ..lineTo(back, at.dy + h / 2)
        ..close();
    }
    if (lit) {
      s.canvas.drawPath(
        path,
        Paint()
          ..color = storyGold.withValues(alpha: 0.8 + 0.2 * sin(s.time * 10))
          ..style = PaintingStyle.stroke
          ..strokeWidth = k * 0.05
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, k * 0.015),
      );
    }
    s.canvas
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = storyInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2, k * 0.008)
          ..strokeJoin = StrokeJoin.round,
      );
  }
}

/// Step by step: stars lie along a winding path on the planet's board, and
/// Koba runs the blocks one after another, collecting every star on the way
/// to the flag.
class SequencingArrival extends BoardArrival {
  const SequencingArrival() : super('sequencing');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalSequencing;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalSequencingKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksSequencing;

  @override
  List<String> get rows => const ['##.*G', '##*##', 'S*.##'];

  @override
  Direction get facing => Direction.east;

  @override
  List<Block> get program => arrivalBlocks(const [
    BlockType.forward,
    BlockType.forward,
    BlockType.turnLeft,
    BlockType.forward,
    BlockType.forward,
    BlockType.turnRight,
    BlockType.forward,
    BlockType.forward,
  ]);
}

/// Loops: the path climbs the planet's board in steps that are all the
/// same, so Koba's program is the same few blocks again and again; after
/// the run each round is marked under the row, and the repeat block pops up:
/// the shortcut Koba asks for.
class LoopsArrival extends BoardArrival {
  const LoopsArrival() : super('loops');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalLoops;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalLoopsKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksLoops;

  @override
  List<String> get rows => const ['###G', '##.*', '#.*#', 'S*##'];

  @override
  Direction get facing => Direction.east;

  /// The part that repeats: step, turn, step, turn.
  static const _round = [
    BlockType.forward,
    BlockType.turnLeft,
    BlockType.forward,
    BlockType.turnRight,
  ];

  @override
  List<Block> get program =>
      arrivalBlocks([..._round, ..._round, ..._round.take(3)]);

  @override
  Duration get kobaLength => const Duration(milliseconds: 10000);

  @override
  double get runTo => 0.72;

  /// When each round's mark shows, and when the repeat block pops up.
  double _markAt(int round) => runEnd + 0.04 + round * 0.06;
  double get _popAt => _markAt(3) + 0.02;

  @override
  List<(double, SoundEffect)> get effects => [
    ...super.effects,
    for (var round = 0; round < 3; round++) (_markAt(round), SoundEffect.poke),
    (_popAt, SoundEffect.drop),
  ];

  @override
  void paintOver(ArrivalStage s, BoardLayout b, BoardMoment? now) {
    if (now == null) return;
    final size = blockSize(s);
    final count = play.row.length;
    for (var round = 0; round < 3; round++) {
      final show = ((s.t - _markAt(round)) / 0.04).clamp(0.0, 1.0);
      if (show == 0) continue;
      final from = blockRect(s, 'm${round * _round.length}')!.center;
      final to = blockRect(
        s,
        'm${min(count, (round + 1) * _round.length) - 1}',
      )!.center;
      // A bracket under the round's blocks, in the repeat block's colour.
      final y = from.dy + size * 0.7;
      final left = from.dx - size * 0.4;
      final right = storyLerp(left, to.dx + size * 0.4, show);
      s.canvas.drawPath(
        Path()
          ..moveTo(left, y - size * 0.12)
          ..lineTo(left, y)
          ..lineTo(right, y)
          ..lineTo(right, y - size * 0.12 * show),
        Paint()
          ..color = BlockType.repeat.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.1
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final pop = Curves.elasticOut.transform(
      ((s.t - _popAt) / 0.08).clamp(0, 1),
    );
    if (pop > 0) {
      // Beside Koba on the finish, bobbing.
      final goal = play.level.goal;
      paintBlock(
        s.canvas,
        BlockType.repeat,
        b.at(goal.x + 1.7, goal.y - 0.2) +
            Offset(0, s.u * 0.012 * sin(s.time * 3)),
        s.u * 0.14 * pop,
        glow: true,
      );
    }
  }
}

/// Magic Block: Koba teaches the Magic Block two steps and a turn in its
/// own row, then the program calls it twice, each call lit as its blocks
/// run, and two more steps reach the flag.
class FunctionsArrival extends BoardArrival {
  const FunctionsArrival() : super('functions');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalFunctions;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalFunctionsKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksFunctions;

  @override
  List<String> get rows => const ['.*.#', '.#.#', 'S#G#'];

  @override
  Direction get facing => Direction.north;

  @override
  List<Block> get magic => arrivalBlocks(const [
    BlockType.forward,
    BlockType.forward,
    BlockType.turnRight,
  ]);

  @override
  List<Block> get program => arrivalBlocks(const [
    BlockType.star,
    BlockType.star,
    BlockType.forward,
    BlockType.forward,
  ]);

  @override
  Duration get kobaLength => const Duration(milliseconds: 9000);
}

/// Look ahead: fog covers the board but for a clearing round Koba; before
/// each step the eye block shines Koba's headlight on the tile ahead, so it
/// stops where the path turns instead of bumping.
class ConditionsArrival extends BoardArrival {
  const ConditionsArrival() : super('conditions');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalConditions;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalConditionsKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksConditions;

  @override
  List<String> get rows => const ['###G', '###.', 'S.*.'];

  @override
  Direction get facing => Direction.east;

  static Block _lookAndStep() => arrivalBlock(
    BlockType.repeat,
    count: 5,
    children: [
      arrivalBlock(
        BlockType.ifPathClear,
        children: [arrivalBlock(BlockType.forward)],
      ),
    ],
  );

  @override
  List<Block> get program => [
    _lookAndStep(),
    arrivalBlock(BlockType.turnLeft),
    _lookAndStep(),
  ];

  @override
  Duration get kobaLength => const Duration(milliseconds: 11000);

  @override
  double get runTo => 0.95;

  @override
  void paintOver(ArrivalStage s, BoardLayout b, BoardMoment? now) {
    final level = play.level;
    final canvas = s.canvas;
    final area = Rect.fromPoints(
      b.at(-0.3, -0.9),
      b.at(level.width + 0.3, level.height + 0.4),
    );
    canvas.saveLayer(area.inflate(b.tile), Paint());
    final fog = Paint()
      ..color = const Color(0xFFE4EAF4).withValues(alpha: 0.85)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.tile * 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(area, Radius.circular(b.tile * 0.6)),
      fog,
    );
    // Wisps drifting over it.
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(
          area.left + area.width * ((i * 0.37 + s.time * 0.02) % 1),
          area.top + area.height * ((i * 0.61 + 0.2) % 1),
        ),
        b.tile * (0.7 + 0.2 * sin(i * 2.0)),
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.tile * 0.3),
      );
    }
    // Clear round Koba and the tiles it has passed, and where it looks.
    final clear = Paint()
      ..blendMode = BlendMode.dstOut
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.tile * 0.3);
    final koba = now?.foot ?? b.foot(level.start.x + 0.0, level.start.y + 0.0);
    canvas.drawCircle(koba - Offset(0, b.tile * 0.4), b.tile * 0.95, clear);
    if (now != null) {
      for (final step in play.steps.take(now.index)) {
        canvas.drawCircle(
          b.at(step.to.x + 0.5, step.to.y + 0.5),
          b.tile * 0.6,
          clear,
        );
      }
      final step = now.step;
      if (step.kind == BoardStepKind.look && !now.done) {
        canvas.drawCircle(
          b.at(step.ahead.x + 0.5, step.ahead.y + 0.5),
          b.tile * 0.65 * sin(pi * now.through),
          clear,
        );
      }
    }
    canvas.restore();
  }
}

/// Step Box: the box stores a 3, its number flies over Koba, and each move
/// block takes as many steps as it says, counted over Koba's head.
class VariablesArrival extends BoardArrival {
  const VariablesArrival() : super('variables');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalVariables;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalVariablesKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksVariables;

  @override
  List<String> get rows => const ['###G', '###.', '###*', 'S.*.'];

  @override
  Direction get facing => Direction.east;

  @override
  List<Block> get program => [
    arrivalBlock(BlockType.setSteps, count: 3),
    arrivalBlock(BlockType.moveSteps),
    arrivalBlock(BlockType.turnLeft),
    arrivalBlock(BlockType.moveSteps),
  ];

  @override
  Duration get kobaLength => const Duration(milliseconds: 8500);

  @override
  void paintOver(ArrivalStage s, BoardLayout b, BoardMoment? now) {
    if (now == null || now.done || s.t < stepAt(0)) return;
    final step = now.step;
    final over = now.foot - Offset(0, b.tile * 1.45);
    final size = b.tile * 0.5;
    final color = BlockType.setSteps.color;
    if (step.kind == BoardStepKind.store) {
      // The number flies from the Step Box block over Koba.
      final from = blockRect(s, step.block!)?.center ?? over;
      final p = Curves.easeInOut.transform(now.through);
      paintStoryNumber(
        s.canvas,
        '${step.value}',
        Offset.lerp(from, over, p)! - Offset(0, sin(pi * p) * b.tile * 0.4),
        size * (1 + 0.3 * sin(pi * p)),
        color,
        glow: true,
      );
      return;
    }
    if (step.kind != BoardStepKind.move ||
        play.byId[step.block]?.type != BlockType.moveSteps) {
      return;
    }
    // Koba counts its steps: 1, 2, 3.
    var count = 1;
    for (var i = now.index - 1; i >= 0; i--) {
      final before = play.steps[i];
      if (before.kind != BoardStepKind.move || before.block != step.block) {
        break;
      }
      count++;
    }
    paintStoryNumber(s.canvas, '$count', over, size, color);
  }
}

/// Fix it!: muddled blocks drop in and Koba runs them into a rock; the
/// block that bumped wears the bump's orange ring and turns into the right
/// one, and Koba goes back and runs the fixed blocks to the flag.
class DebuggingArrival extends BoardArrival {
  const DebuggingArrival() : super('debugging');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalDebugging;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalDebuggingKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksDebugging;

  @override
  List<String> get rows => const ['##*G', 'S..#', '####'];

  @override
  Direction get facing => Direction.east;

  @override
  List<Block> get program => arrivalBlocks(const [
    BlockType.forward,
    BlockType.forward,
    BlockType.turnLeft,
    BlockType.forward,
    BlockType.turnRight,
    BlockType.forward,
  ]);

  @override
  List<Block> get muddled => arrivalBlocks(const [
    BlockType.forward,
    BlockType.forward,
    BlockType.forward,
    BlockType.forward,
    BlockType.turnRight,
    BlockType.forward,
  ]);

  @override
  Duration get kobaLength => const Duration(milliseconds: 11000);

  @override
  double get runTo => 0.95;
}

/// Until the flag: a long road to a far flag, and one until-the-flag block
/// holding a single step keeps Koba rolling all the way.
class UntilArrival extends BoardArrival {
  const UntilArrival() : super('until');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalUntil;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalUntilKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksUntil;

  @override
  List<String> get rows => const ['#######', 'S.*..*G', '#######'];

  @override
  Direction get facing => Direction.east;

  @override
  List<Block> get program => [
    arrivalBlock(
      BlockType.untilGoal,
      children: [arrivalBlock(BlockType.forward)],
    ),
  ];
}

/// Otherwise: at every spot Koba's headlight looks ahead; where the way is
/// clear it goes, and where a bush (or the edge) is in the way it turns, so
/// one two-row eye block in a repeat takes it round to the flag.
class OtherwiseArrival extends BoardArrival {
  const OtherwiseArrival() : super('otherwise');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalOtherwise;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalOtherwiseKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksOtherwise;

  @override
  List<String> get rows => const ['S..#', '##*#', '#G.#'];

  @override
  Direction get facing => Direction.east;

  @override
  List<Block> get program => [
    arrivalBlock(
      BlockType.repeat,
      count: 7,
      children: [
        arrivalBlock(
          BlockType.ifElse,
          children: [arrivalBlock(BlockType.forward)],
          otherwise: [arrivalBlock(BlockType.turnRight)],
        ),
      ],
    ),
  ];

  @override
  Duration get kobaLength => const Duration(milliseconds: 11000);

  @override
  double get runTo => 0.95;
}

/// [text] (a number or "!") centred on [c], [size] tall, in [color] with an
/// ink outline (unless not [outline]) and with [glow] a gold shine behind.
void paintStoryNumber(
  Canvas canvas,
  String text,
  Offset c,
  double size,
  Color color, {
  bool outline = true,
  bool glow = false,
  double opacity = 1,
}) {
  if (size <= 0 || opacity <= 0) return;
  if (glow) {
    canvas.drawCircle(
      c,
      size * 0.7,
      Paint()
        ..color = storyGold.withValues(alpha: 0.6 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.3),
    );
  }
  TextPainter painter(Paint? stroke) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 1,
        color: stroke == null ? color.withValues(alpha: opacity) : null,
        foreground: stroke,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final layers = [
    if (outline)
      painter(
        Paint()
          ..color = storyInk.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.14
          ..strokeJoin = StrokeJoin.round,
      ),
    painter(null),
  ];
  for (final layer in layers) {
    layer
      ..paint(canvas, c - Offset(layer.width / 2, layer.height / 2))
      ..dispose();
  }
}

/// A block from the editor, its colour with its white sign, [size] wide and
/// centred on [c]; with [glow] a gold ring shines round it.
void paintBlock(
  Canvas canvas,
  BlockType type,
  Offset c,
  double size, {
  bool glow = false,
}) {
  if (size <= 0) return;
  final rect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: c, width: size, height: size),
    Radius.circular(size * 0.22),
  );
  if (glow) {
    canvas.drawRRect(
      rect.inflate(size * 0.08),
      Paint()
        ..color = storyGold
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.12),
    );
  }
  canvas
    ..drawRRect(rect, Paint()..color = type.color)
    ..drawRRect(
      rect,
      Paint()
        ..color = storyInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, size * 0.05),
    );
  final icon = type.icon;
  final sign = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: size * 0.7,
        color: const Color(0xFFFFFFFF),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  sign.paint(canvas, c - Offset(sign.width / 2, sign.height / 2));
  sign.dispose();
}
