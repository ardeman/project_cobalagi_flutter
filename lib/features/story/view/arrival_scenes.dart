import 'dart:math';

import 'package:flutter/animation.dart';
import 'dart:ui' show Gradient;

import 'package:flutter/painting.dart' hide Gradient;

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
    StoryArt? art,
  ) {
    final (box, u) = storyBox(stage);
    return ArrivalStage._(canvas, box, u, frame, art);
  }

  ArrivalStage._(this.canvas, this.box, this.u, this.frame, this.art);

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
  List<BlockType> get blocks => const [
    BlockType.forward,
    BlockType.turnLeft,
    BlockType.forward,
    BlockType.forward,
    BlockType.turnRight,
    BlockType.forward,
    BlockType.forward,
  ];

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
  List<BlockType> get blocks => const [
    BlockType.forward,
    BlockType.forward,
    BlockType.turnLeft,
    BlockType.forward,
    BlockType.forward,
    BlockType.turnRight,
    BlockType.forward,
    BlockType.forward,
  ];
}

/// Loops: the path climbs in steps that are all the same, and Koba climbs
/// them one by one, then wonders about a shortcut: the repeat block's sign.
class LoopsArrival extends ArrivalScene {
  const LoopsArrival() : super('loops');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalLoops;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalLoopsKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksLoops;

  static const _steps = 5;

  /// How many steps Koba climbs, one per [_climb] of its beat.
  static const _climbed = 3;
  static const _climb = 0.18;

  @override
  List<(double, SoundEffect)> get effects => [
    for (var i = 1; i <= _climbed; i++) (i * _climb, SoundEffect.step),
  ];

  /// The top of step [i] (0 is the ground in front of the first), where
  /// Koba stands.
  Offset _top(ArrivalStage s, int i) =>
      Offset(s.x(0.36 + 0.11 * i), s.ground - s.u * 0.08 * i);

  @override
  void paintPlanet(ArrivalStage s) {
    paintObstacle(
      s.canvas,
      theme.obstacle,
      s.at(0.5, 0.92),
      s.u * 0.1,
      seed: 2,
    );
    // One staircase, every step the same, sunk a little into the hill.
    final half = s.box.width * 0.055;
    final bottom = s.ground + s.u * 0.08;
    final stairs = Path()..moveTo(_top(s, 1).dx - half, bottom);
    for (var i = 1; i <= _steps; i++) {
      final top = _top(s, i);
      stairs
        ..lineTo(top.dx - half, top.dy)
        ..lineTo(top.dx + half, top.dy);
    }
    stairs
      ..lineTo(_top(s, _steps).dx + half, bottom)
      ..close();
    final edge = Paint()
      ..color = theme.floorEdge
      ..strokeWidth = max(2, s.u * 0.006);
    s.canvas.drawPath(stairs, Paint()..color = theme.floor);
    for (var i = 1; i <= _steps; i++) {
      final top = _top(s, i);
      // Each step's tread, and the seam below it.
      s.canvas
        ..drawRect(
          Rect.fromLTRB(
            top.dx - half,
            top.dy,
            top.dx + half,
            top.dy + s.u * 0.02,
          ),
          Paint()..color = theme.floorEdge,
        )
        ..drawLine(
          Offset(top.dx + half, top.dy + s.u * 0.08),
          Offset(top.dx + half, bottom),
          edge,
        );
    }
    s.canvas.drawPath(
      stairs,
      Paint()
        ..color = storyInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, s.u * 0.006)
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  void paintKobaBeat(ArrivalStage s) {
    final climbing = (s.t / _climb).floor();
    if (climbing < _climbed) {
      final p = Curves.easeInOut.transform(s.t / _climb - climbing);
      final from = _top(s, climbing);
      final to = _top(s, climbing + 1);
      s.koba(
        Offset.lerp(from, to, p)! + Offset(0, -sin(pi * p) * s.u * 0.06),
        size: s.u * 0.32,
        angle: -0.1 * sin(pi * p),
      );
      // The same little arrows over every step climbed: step, turn, step…
      for (var i = 1; i <= climbing; i++) {
        _pattern(s, i);
      }
      return;
    }
    for (var i = 1; i <= _climbed; i++) {
      _pattern(s, i);
    }
    // Koba stops and wonders: the repeat block's sign pops up.
    final pop = Curves.elasticOut.transform(
      ((s.t - _climbed * _climb) / 0.25).clamp(0, 1),
    );
    final top = _top(s, _climbed);
    s.koba(
      top,
      size: s.u * 0.32,
      face: RobotFace.cheer,
      gaze: const Offset(0, -14),
    );
    if (pop > 0) {
      paintBlock(
        s.canvas,
        BlockType.repeat,
        top + Offset(0, -s.u * (0.42 + 0.02 * sin(s.time * 3))),
        s.u * 0.14 * pop,
      );
    }
  }

  /// A small "up, then right" mark over step [i]: the part that repeats.
  void _pattern(ArrivalStage s, int i) {
    final c = _top(s, i) + Offset(-s.u * 0.02, -s.u * 0.3);
    final paint = Paint()
      ..color = BlockType.repeat.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.u * 0.012
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final d = s.u * 0.035;
    s.canvas.drawPath(
      Path()
        ..moveTo(c.dx - d, c.dy + d)
        ..lineTo(c.dx - d, c.dy - d)
        ..lineTo(c.dx + d, c.dy - d)
        ..moveTo(c.dx + d * 0.5, c.dy - d * 1.5)
        ..lineTo(c.dx + d, c.dy - d)
        ..lineTo(c.dx + d * 0.5, c.dy - d * 0.5),
      paint,
    );
  }
}

/// Magic Block: a sparkling star block lies on the ground; Koba's moves fly
/// into it, then copies of it pop out, ready to use again and again.
class FunctionsArrival extends ArrivalScene {
  const FunctionsArrival() : super('functions');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalFunctions;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalFunctionsKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksFunctions;

  static const _moves = [
    BlockType.forward,
    BlockType.turnLeft,
    BlockType.forward,
  ];

  @override
  List<(double, SoundEffect)> get effects => const [
    (0.6, SoundEffect.drop),
    (0.72, SoundEffect.drop),
    (0.84, SoundEffect.drop),
  ];

  Offset _block(ArrivalStage s) =>
      Offset(s.x(0.66), s.ground - s.u * (0.16 + 0.02 * sin(s.time * 2)));

  @override
  void paintPlanet(ArrivalStage s) {
    paintObstacle(s.canvas, theme.obstacle, s.on(0.94), s.u * 0.22);
    paintObstacle(s.canvas, theme.obstacle, s.on(0.48), s.u * 0.12, seed: 4);
    final c = _block(s);
    // Sparkles twinkling round it.
    for (var i = 0; i < 5; i++) {
      final a = s.time * 0.8 + i * 2 * pi / 5;
      paintStoryStar(
        s.canvas,
        c + Offset(cos(a) * s.u * 0.13, sin(a) * s.u * 0.09),
        s.u * 0.015,
        opacity: 0.5 + 0.5 * sin(s.time * 4 + i),
        turn: s.time + i,
      );
    }
    final learnt = s.frame.beat == 1 && s.t > 0.5;
    paintBlock(s.canvas, BlockType.star, c, s.u * 0.14, glow: learnt);
  }

  @override
  void paintKobaBeat(ArrivalStage s) {
    s.koba(
      s.kobaAt,
      face: s.t > 0.55 ? RobotFace.cheer : RobotFace.normal,
      gaze: const Offset(10, -6),
    );
    final target = _block(s);
    final from = s.kobaAt + Offset(s.u * 0.08, -s.u * 0.36);
    // Koba's moves fly one by one into the block.
    for (var i = 0; i < _moves.length; i++) {
      final p = ((s.t - 0.05 - i * 0.13) / 0.25).clamp(0.0, 1.0);
      if (p == 0 || p == 1) continue;
      final c =
          Offset.lerp(from, target, Curves.easeIn.transform(p))! +
          Offset(0, -sin(pi * p) * s.u * 0.12);
      paintBlock(s.canvas, _moves[i], c, s.u * 0.09 * (1 - 0.4 * p));
    }
    // Then it makes copies of itself, again and again.
    for (var i = 0; i < 3; i++) {
      final p = ((s.t - 0.6 - i * 0.12) / 0.2).clamp(0.0, 1.0);
      if (p == 0) continue;
      final to = target + Offset(s.u * (-0.14 + 0.14 * i), -s.u * 0.3);
      paintBlock(
        s.canvas,
        BlockType.star,
        Offset.lerp(target, to, Curves.easeOutBack.transform(p))!,
        s.u * 0.09,
      );
    }
  }
}

/// Look ahead: fog hides the way; Koba switches on its headlight, the beam
/// clears the fog ahead and shows the ice spike in the way.
class ConditionsArrival extends ArrivalScene {
  const ConditionsArrival() : super('conditions');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalConditions;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalConditionsKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksConditions;

  /// How bright the headlight is, 0 to 1.
  double _light(ArrivalStage s) => s.frame.beat == 1
      ? Curves.easeOut.transform(((s.t - 0.15) / 0.25).clamp(0, 1))
      : 0;

  /// The beam, from Koba's head out over the ground ahead.
  Path _beam(ArrivalStage s) {
    final scale = s.kobaSize / 512;
    // Koba's head, in its 512-pixel picture, from its feet at (270, 500).
    final lamp = s.kobaAt + const Offset(110, -285) * scale;
    final reach = s.x(0.86);
    return Path()
      ..moveTo(lamp.dx, lamp.dy - s.u * 0.02)
      ..lineTo(reach, s.ground - s.u * 0.34)
      ..quadraticBezierTo(
        reach + s.u * 0.08,
        s.ground - s.u * 0.14,
        reach,
        s.ground + s.u * 0.06,
      )
      ..lineTo(lamp.dx, lamp.dy + s.u * 0.02)
      ..close();
  }

  @override
  void paintPlanet(ArrivalStage s) {
    paintObstacle(s.canvas, theme.obstacle, s.on(0.72), s.u * 0.22);
    paintObstacle(s.canvas, theme.obstacle, s.on(0.94), s.u * 0.16, seed: 6);
  }

  @override
  void paintKobaBeat(ArrivalStage s) {
    s.koba(
      s.kobaAt,
      face: s.t > 0.65 ? RobotFace.cheer : RobotFace.normal,
      gaze: const Offset(12, 0),
    );
  }

  @override
  void paintFront(ArrivalStage s) {
    final light = _light(s);
    final canvas = s.canvas;
    final beam = _beam(s);
    // Banks of fog over the way ahead, drifting a little.
    void fog(double opacity) {
      for (var i = 0; i < 9; i++) {
        final c = Offset(
          s.x(0.6 + 0.06 * i) + sin(s.time * 0.5 + i) * s.u * 0.03,
          s.y(0.7 + 0.12 * ((i * 0.37) % 1.0)),
        );
        canvas.drawOval(
          Rect.fromCenter(center: c, width: s.u * 0.45, height: s.u * 0.28),
          Paint()
            ..color = const Color(0xFFE8F1FA).withValues(alpha: 0.75 * opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.u * 0.04),
        );
      }
    }

    if (light == 0) {
      fog(1);
      return;
    }
    // The headlight's beam thins the fog in it as it comes on.
    canvas
      ..save()
      ..clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(s.box.inflate(s.u)),
          beam,
        ),
      );
    fog(1);
    canvas
      ..restore()
      ..save()
      ..clipPath(beam);
    fog(1 - 0.75 * light);
    canvas.restore();
    // Warm light, brightest at the lamp.
    final bounds = beam.getBounds();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = Gradient.linear(bounds.centerLeft, bounds.centerRight, [
          const Color(0xFFFFE27A).withValues(alpha: 0.8 * light),
          const Color(0xFFFFE27A).withValues(alpha: 0.3 * light),
        ])
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.u * 0.02),
    );
  }
}

/// Step Box: a little box on the ground holds a number; it pops out over
/// Koba, who rolls that many steps, counting them on the tiles.
class VariablesArrival extends ArrivalScene {
  const VariablesArrival() : super('variables');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalVariables;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalVariablesKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksVariables;

  static const _count = 3;

  /// When, in Koba's beat, it starts rolling, and how long each step takes.
  static const _go = 0.36;
  static const _stepLength = 0.18;

  /// Where step [i] ends (0 is where Koba stopped).
  Offset _tile(ArrivalStage s, int i) => s.on(0.36 + 0.13 * i);

  /// The box, past the last tile.
  Offset _box(ArrivalStage s) => s.on(0.86);

  @override
  List<(double, SoundEffect)> get effects => [
    (0.1, SoundEffect.drop),
    for (var i = 1; i <= _count; i++) (_go + _stepLength * i, SoundEffect.step),
  ];

  @override
  void paintPlanet(ArrivalStage s) {
    paintObstacle(s.canvas, theme.obstacle, s.on(0.96), s.u * 0.2);
    final open = s.frame.beat == 1
        ? Curves.easeOut.transform((s.t / 0.15).clamp(0, 1))
        : 0.0;
    _stepBox(s, _box(s), s.u * 0.16, open);
    final reached = s.frame.beat == 1
        ? ((s.t - _go) / _stepLength).floor().clamp(0, _count)
        : 0;
    for (var i = 1; i <= _count; i++) {
      final c = _tile(s, i);
      final tile = Rect.fromCenter(
        center: c,
        width: s.u * 0.16,
        height: s.u * 0.05,
      );
      s.canvas
        ..drawOval(tile, Paint()..color = theme.floor)
        ..drawOval(
          tile,
          Paint()
            ..color = storyInk
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, s.u * 0.006),
        );
      // Each step counted as Koba reaches its tile.
      if (i <= reached) {
        paintStoryNumber(
          s.canvas,
          '$i',
          c + Offset(s.u * 0.05, -s.u * 0.12),
          s.u * 0.07,
          BlockType.setSteps.color,
        );
      }
    }
  }

  /// The Step Box at [base], [size] wide, its lid [open] (0 to 1).
  void _stepBox(ArrivalStage s, Offset base, double size, double open) {
    final body = Rect.fromLTWH(
      base.dx - size / 2,
      base.dy - size * 0.7,
      size,
      size * 0.7,
    );
    final ink = Paint()
      ..color = storyInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2, s.u * 0.007)
      ..strokeJoin = StrokeJoin.round;
    final colour = BlockType.setSteps.color;
    final box = RRect.fromRectAndRadius(body, Radius.circular(size * 0.1));
    s.canvas
      ..drawRRect(box, Paint()..color = colour)
      ..drawRRect(box, ink);
    paintStoryNumber(
      s.canvas,
      '$_count',
      body.center,
      size * 0.45,
      const Color(0xFFFFFFFF),
      outline: false,
    );
    // The lid swings up from the back edge.
    s.canvas
      ..save()
      ..translate(body.right, body.top)
      ..rotate(1.1 * open);
    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(-size * 1.04, -size * 0.14, size * 1.08, size * 0.16),
      Radius.circular(size * 0.06),
    );
    s.canvas
      ..drawRRect(
        lid,
        Paint()..color = Color.lerp(colour, const Color(0xFFFFFFFF), 0.2)!,
      )
      ..drawRRect(lid, ink)
      ..restore();
  }

  @override
  void paintKobaBeat(ArrivalStage s) {
    final rolled = ((s.t - _go) / _stepLength).clamp(0.0, _count.toDouble());
    final step = rolled.floor().clamp(0, _count - 1);
    final p = Curves.easeInOut.transform(rolled - step);
    final base = rolled >= _count
        ? _tile(s, _count)
        : Offset.lerp(_tile(s, step), _tile(s, step + 1), p)!;
    final done = rolled >= _count;
    s.koba(
      base,
      size: s.u * 0.36,
      face: done ? RobotFace.cheer : RobotFace.normal,
      angle: rolled > 0 && !done ? 0.05 * sin(s.time * 14) : 0,
      gaze: s.t < _go ? const Offset(10, -10) : Offset.zero,
    );
    // The number flies out of the box and stays over Koba while it counts.
    final fly = Curves.easeInOut.transform(((s.t - 0.1) / 0.24).clamp(0, 1));
    if (fly == 0) return;
    final box = _box(s) - Offset(0, s.u * 0.2);
    final over = base - Offset(0, s.u * 0.42);
    paintStoryNumber(
      s.canvas,
      '$_count',
      Offset.lerp(box, over, fly)! + Offset(0, -sin(pi * fly) * s.u * 0.1),
      s.u * 0.1,
      BlockType.setSteps.color,
      glow: true,
    );
  }
}

/// Fix it!: blocks lie muddled on the path; they line up, the one that
/// isn't right wears the bump's orange ring, and Koba flips it to the
/// right one.
class DebuggingArrival extends ArrivalScene {
  const DebuggingArrival() : super('debugging');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalDebugging;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalDebuggingKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksDebugging;

  /// The blocks left behind; the middle one is the one to fix.
  static const _left = [
    BlockType.forward,
    BlockType.turnLeft,
    BlockType.forward,
  ];
  static const _fixed = BlockType.turnRight;

  /// How each block lies muddled: turned, and how far off its spot.
  static const _muddle = [(-0.5, -0.03), (0.7, 0.04), (-0.25, 0.02)];

  @override
  List<(double, SoundEffect)> get effects => const [
    (0.3, SoundEffect.bumpWood),
    (0.7, SoundEffect.drop),
  ];

  @override
  void paintPlanet(ArrivalStage s) {
    paintObstacle(s.canvas, theme.obstacle, s.on(0.96), s.u * 0.18);
    final beat = s.frame.beat == 1;
    // They line up first.
    final tidy = beat
        ? Curves.easeInOut.transform((s.t / 0.22).clamp(0, 1))
        : 0.0;
    final flip = beat ? ((s.t - 0.6) / 0.16).clamp(0.0, 1.0) : 0.0;
    final size = s.u * 0.14;
    for (var i = 0; i < _left.length; i++) {
      final (turn, off) = _muddle[i];
      final spot = s.on(0.56 + 0.15 * i) - Offset(0, size * 0.62);
      final c = spot + Offset(0, off * s.u * (1 - tidy));
      final wrong = i == 1;
      var type = _left[i];
      var width = 1.0;
      if (wrong && flip > 0) {
        // Flips over like a card, the right block on its other side.
        width = (1 - 2 * flip).abs();
        if (flip > 0.5) type = _fixed;
      }
      s.canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(turn * (1 - tidy))
        ..scale(width, 1);
      final ring = wrong && beat && s.t > 0.3;
      if (ring && flip < 0.5) _ring(s, size, BlockTile.bumpedColor);
      paintBlock(s.canvas, type, Offset.zero, size, glow: flip >= 1);
      s.canvas.restore();
      if (ring && flip == 0) _badge(s, c + Offset(size * 0.5, -size * 0.5));
    }
  }

  /// The bump's orange ring round a block [size] wide, outside a white gap.
  void _ring(ArrivalStage s, double size, Color color) {
    final pulse = 1 + 0.04 * sin(s.time * 8);
    RRect ring(double grow) => RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: size * grow * pulse,
        height: size * grow * pulse,
      ),
      Radius.circular(size * 0.3),
    );
    s.canvas
      ..drawRRect(
        ring(1.3),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.1,
      )
      ..drawRRect(
        ring(1.12),
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.07,
      );
  }

  /// The bump's "!" badge at [c].
  void _badge(ArrivalStage s, Offset c) {
    final r = s.u * 0.03;
    s.canvas
      ..drawCircle(c, r, Paint()..color = BlockTile.bumpedColor)
      ..drawCircle(
        c,
        r,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.25,
      );
    paintStoryNumber(
      s.canvas,
      '!',
      c,
      r * 1.4,
      const Color(0xFFFFFFFF),
      outline: false,
    );
  }

  @override
  void paintKobaBeat(ArrivalStage s) {
    s.koba(
      s.kobaAt,
      face: s.t > 0.75 ? RobotFace.cheer : RobotFace.normal,
      gaze: const Offset(10, 4),
    );
  }
}

/// Until the flag: a long road runs to a flag far away; Koba starts to
/// count the steps, gives up, and the until-the-flag block sends it
/// rolling along without counting.
class UntilArrival extends ArrivalScene {
  const UntilArrival() : super('until');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalUntil;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalUntilKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksUntil;

  static const _tiles = 12;

  /// When, in Koba's beat, it starts to count, the block pops up and Koba
  /// sets off.
  static const _counted = 4;
  static const _countStep = 0.08;
  static const _pop = 0.5;
  static const _go = 0.62;

  @override
  List<(double, SoundEffect)> get effects => [
    for (var i = 1; i <= _counted; i++) (i * _countStep, SoundEffect.turn),
    (_pop, SoundEffect.drop),
  ];

  /// Where tile [i] of the road is (0 under Koba) and how big, the road
  /// shrinking towards the far hill.
  (Offset, double) _tile(ArrivalStage s, double i) {
    final p = i / _tiles;
    final ease = 1 - pow(1 - p, 1.6).toDouble();
    final from = s.kobaAt;
    final to = _flag(s) + Offset(-s.u * 0.04, s.u * 0.005);
    return (Offset.lerp(from, to, ease)!, storyLerp(1, 0.22, ease));
  }

  Offset _flag(ArrivalStage s) => s.at(0.9, 0.66);

  @override
  void paintPlanet(ArrivalStage s) {
    final canvas = s.canvas;
    // A far hill, with the flag on top.
    final hill = Rect.fromCenter(
      center: s.at(0.88, 0.7),
      width: s.u * 0.5,
      height: s.u * 0.14,
    );
    canvas
      ..drawOval(hill, Paint()..color = theme.groundSide)
      ..drawOval(
        hill,
        Paint()
          ..color = storyInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2, s.u * 0.005),
      );
    final wave = 0.04 * sin(s.time * 4);
    final flag = s.u * 0.12;
    canvas
      ..save()
      ..translate(_flag(s).dx - flag * 0.38, _flag(s).dy - flag * 0.8)
      ..scale(flag)
      ..rotate(wave);
    drawFinish(canvas, Finish.flag);
    canvas.restore();
    paintObstacle(
      canvas,
      theme.obstacle,
      s.on(0.66) + Offset(0, s.u * 0.05),
      s.u * 0.16,
      seed: 4,
    );
    // The road: tiles all the way, smaller and smaller.
    for (var i = _tiles; i >= 1; i--) {
      final (c, scale) = _tile(s, i.toDouble());
      final tile = Rect.fromCenter(
        center: c,
        width: s.u * 0.13 * scale,
        height: s.u * 0.04 * scale,
      );
      canvas
        ..drawOval(tile, Paint()..color = theme.floor)
        ..drawOval(
          tile,
          Paint()
            ..color = theme.floorEdge
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.5, s.u * 0.005 * scale),
        );
    }
    // Koba counts the first few, then gives up: too many.
    if (s.frame.beat == 1 && s.t < _go) {
      final shown = (s.t / _countStep).floor().clamp(0, _counted);
      for (var i = 1; i <= shown; i++) {
        final (c, scale) = _tile(s, i.toDouble());
        paintStoryNumber(
          canvas,
          '$i',
          c - Offset(0, s.u * 0.08 * scale),
          s.u * 0.06 * scale,
          storyGold,
          opacity: s.t > _pop ? 1 - (s.t - _pop) / (_go - _pop) : 1,
        );
      }
    }
  }

  @override
  void paintKobaBeat(ArrivalStage s) {
    final go = Curves.easeIn.transform(((s.t - _go) / (1 - _go)).clamp(0, 1));
    final (base, scale) = _tile(s, go * 6);
    final dizzy = s.t > _counted * _countStep + 0.05 && s.t < _pop;
    s.koba(
      base,
      size: s.kobaSize * scale,
      face: dizzy
          ? RobotFace.dizzy
          : s.t > _pop
          ? RobotFace.cheer
          : RobotFace.normal,
      angle: go > 0 ? 0.05 * sin(s.time * 14) : 0,
      gaze: const Offset(12, -4),
    );
    final pop = Curves.elasticOut.transform(((s.t - _pop) / 0.2).clamp(0, 1));
    if (pop > 0) {
      paintBlock(
        s.canvas,
        BlockType.untilGoal,
        base - Offset(0, s.u * (0.5 * scale + 0.02 * sin(s.time * 3))),
        s.u * 0.14 * pop * max(scale, 0.7),
      );
    }
  }
}

/// Otherwise: the road forks, a bush blocks the way ahead; the two-row eye
/// block pops up, and Koba turns and takes the clear way to a star.
class OtherwiseArrival extends ArrivalScene {
  const OtherwiseArrival() : super('otherwise');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalOtherwise;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalOtherwiseKoba;

  @override
  String thanksWords(AppLocalizations l10n) => l10n.storyThanksOtherwise;

  /// When, in Koba's beat, it reaches the fork, the block pops up, Koba
  /// turns, and it reaches the star.
  static const _atFork = 0.22;
  static const _pop = 0.28;
  static const _turn = 0.5;
  static const _star = 0.92;

  @override
  List<(double, SoundEffect)> get effects => const [
    (_pop, SoundEffect.drop),
    (_turn, SoundEffect.turn),
    (_star, SoundEffect.star),
  ];

  Offset _fork(ArrivalStage s) => s.on(0.56);

  /// The way ahead, past the bush.
  Offset _ahead(ArrivalStage s) => s.on(0.96);

  /// The clear way's end, nearer the child than the way ahead.
  Offset _clear(ArrivalStage s) => s.on(0.74) + Offset(0, s.u * 0.085);

  /// The clear way at [p] (0 the fork, 1 its end), curving towards the
  /// child, and how big things are there.
  (Offset, double) _way(ArrivalStage s, double p) {
    final a = _fork(s);
    final b = _clear(s);
    final bend = Offset(a.dx + s.u * 0.02, b.dy);
    final q = 1 - p;
    return (a * q * q + bend * 2 * q * p + b * p * p, storyLerp(1, 1.15, p));
  }

  @override
  void paintPlanet(ArrivalStage s) {
    final canvas = s.canvas;
    void tiles(
      Offset Function(double) at,
      double Function(double) scale,
      int count,
    ) {
      for (var i = count; i >= 1; i--) {
        final p = i / count;
        final c = at(p);
        final k = scale(p);
        final tile = Rect.fromCenter(
          center: c,
          width: s.u * 0.12 * k,
          height: s.u * 0.04 * k,
        );
        canvas
          ..drawOval(tile, Paint()..color = theme.floor)
          ..drawOval(
            tile,
            Paint()
              ..color = theme.floorEdge
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(1.5, s.u * 0.005 * k),
          );
      }
    }

    // The way from Koba to the fork, and on to the bush.
    tiles((p) => Offset.lerp(s.kobaAt, _fork(s), p)!, (_) => 1, 2);
    tiles((p) => Offset.lerp(_fork(s), _ahead(s), p)!, (_) => 1, 3);
    paintObstacle(canvas, theme.obstacle, s.on(0.84), s.u * 0.2, seed: 1);
    // The clear way, nearer the child, with the star at its end.
    tiles((p) => _way(s, p).$1, (p) => _way(s, p).$2, 4);
    final taken = s.frame.beat == 1 ? (s.t - _star) / 0.08 : -1.0;
    if (taken < 1) {
      final pop = taken > 0 ? taken : 0.0;
      paintStoryStar(
        canvas,
        _clear(s) -
            Offset(0, s.u * (0.1 + 0.015 * sin(s.time * 3) + 0.08 * pop)),
        s.u * 0.035 * (1 + pop),
        opacity: 1 - pop,
        turn: s.time,
      );
    }
  }

  @override
  void paintKobaBeat(ArrivalStage s) {
    final t = s.t;
    Offset base;
    var scale = 1.0;
    var face = RobotFace.normal;
    var front = false;
    if (t < _atFork) {
      base = Offset.lerp(
        s.kobaAt,
        _fork(s),
        Curves.easeInOut.transform(t / _atFork),
      )!;
    } else if (t < _turn) {
      // Looks ahead at the bush.
      base = _fork(s);
    } else if (t < _turn + 0.08) {
      // Turns to the clear way.
      base = _fork(s);
      front = true;
    } else {
      final p = Curves.easeInOut.transform(
        ((t - _turn - 0.08) / (_star - _turn - 0.08)).clamp(0, 1),
      );
      (base, scale) = _way(s, p);
      face = p >= 1 ? RobotFace.cheer : RobotFace.normal;
    }
    s.koba(
      base,
      size: s.u * 0.34 * scale,
      face: face,
      front: front,
      angle: t < _atFork || (t > _turn + 0.08 && t < _star)
          ? 0.05 * sin(s.time * 14)
          : 0,
    );
    // The eye block with its two rows, over Koba at the fork.
    final pop = Curves.elasticOut.transform(((t - _pop) / 0.2).clamp(0, 1));
    final fade = 1 - ((t - _turn - 0.1) / 0.15).clamp(0.0, 1.0);
    if (pop > 0 && fade > 0) {
      paintBlock(
        s.canvas,
        BlockType.ifElse,
        _fork(s) - Offset(0, s.u * (0.46 + 0.02 * sin(s.time * 3))),
        s.u * 0.14 * pop * fade,
      );
    }
  }
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
