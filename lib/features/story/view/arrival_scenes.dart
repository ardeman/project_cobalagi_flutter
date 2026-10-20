import 'dart:math';

import 'package:flutter/animation.dart';
import 'dart:ui' show Gradient;

import 'package:flutter/painting.dart' hide Gradient;

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_tile.dart';
import 'package:cobalagi/features/play/view/world/world_theme.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
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

  /// Sounds in Koba's beat, by when (0 to 1).
  List<(double, SoundEffect)> get effects => const [];

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
      length: const Duration(milliseconds: 5500),
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
    paintGround(
      canvas,
      s.box,
      s.ground,
      color: theme.ground,
      side: theme.groundSide,
    );
    paintPlanet(s);
    final shipX = s.x(0.14);
    final shipGround = s.on(0.14).dy;
    if (frame.beat == 0) {
      // The ship comes down beside the planet's puzzle, and Koba rolls out.
      final t = frame.t;
      final down = Curves.easeOut.transform((t / 0.45).clamp(0, 1));
      final landed = t >= 0.45;
      final base = Offset(
        shipX,
        storyLerp(s.box.top - s.u * 0.2, shipGround, down),
      );
      if (landed) paintDust(canvas, base, s.u, ((t - 0.45) / 0.3).clamp(0, 1));
      final out = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
      if (art != null) {
        paintShip(
          canvas,
          art,
          landed ? ShipView.landed : ShipView.landing,
          base: base,
          size: s.shipSize,
          koba: out == 0,
          time: frame.time,
        );
        if (out > 0) {
          s.koba(
            Offset(
              storyLerp(shipX, s.kobaAt.dx, Curves.easeOut.transform(out)),
              s.kobaAt.dy,
            ),
            angle: out < 1 ? 0.05 * sin(frame.time * 14) : 0,
          );
        }
      }
    } else {
      if (art != null) {
        paintShip(
          canvas,
          art,
          ShipView.landed,
          base: Offset(shipX, shipGround),
          size: s.shipSize,
          koba: false,
          time: frame.time,
        );
      }
      paintKobaBeat(s);
    }
    paintFront(s);
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

  /// The ground at [fx] across the box: the hill's top is at [ground], and
  /// it curves down towards the sides.
  Offset on(double fx) {
    final r = box.width * 2.5;
    final d = (fx - 0.5) * box.width;
    return Offset(x(fx), ground + r - sqrt(r * r - d * d));
  }

  double x(double fraction) => box.left + fraction * box.width;
  double y(double fraction) => box.top + fraction * box.height;
  Offset at(double fx, double fy) => Offset(x(fx), y(fy));

  /// Koba standing at [base] (by default where it stopped), from the side.
  void koba(
    Offset base, {
    RobotFace face = RobotFace.normal,
    double? size,
    bool front = false,
    bool mirror = false,
    double angle = 0,
    Offset gaze = Offset.zero,
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
      mirror: mirror,
      angle: angle,
      gaze: gaze,
    );
  }
}

/// Directions: signposts point every way, and Koba looks each way in turn
/// as their arrows light up, in the colours of the arrow blocks.
class DirectionsArrival extends ArrivalScene {
  const DirectionsArrival() : super('directions');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalDirections;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalDirectionsKoba;

  @override
  void paintPlanet(ArrivalStage s) {
    paintObstacle(s.canvas, theme.obstacle, s.on(0.93), s.u * 0.2);
    paintObstacle(s.canvas, theme.obstacle, s.on(0.5), s.u * 0.12, seed: 3);
    // Which arrow is lit: right, then left, then forward.
    final lit = s.frame.beat == 1 ? (s.t * 3).floor().clamp(0, 2) : -1;
    final post = s.on(0.68);
    final top = post.dy - s.u * 0.62;
    s.canvas
      ..drawLine(
        post,
        Offset(post.dx, top),
        Paint()
          ..color = storyInk
          ..strokeWidth = s.u * 0.035
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        post,
        Offset(post.dx, top),
        Paint()
          ..color = const Color(0xFFB98A5E)
          ..strokeWidth = s.u * 0.022
          ..strokeCap = StrokeCap.round,
      );
    _signArrow(s, Offset(post.dx, top), 0, BlockType.forward.color, lit == 2);
    _signArrow(
      s,
      Offset(post.dx, top + s.u * 0.2),
      1,
      BlockType.turnRight.color,
      lit == 0,
    );
    _signArrow(
      s,
      Offset(post.dx, top + s.u * 0.33),
      -1,
      BlockType.turnLeft.color,
      lit == 1,
    );
  }

  /// A board on the post at [at] pointing [side]ways (1 right, -1 left) or,
  /// with 0, up (forward), glowing when [lit].
  void _signArrow(ArrivalStage s, Offset at, int side, Color color, bool lit) {
    final h = s.u * 0.1;
    final w = s.u * 0.24;
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
          ..strokeWidth = s.u * 0.05
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.u * 0.015),
      );
    }
    s.canvas
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = storyInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2, s.u * 0.008)
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  void paintKobaBeat(ArrivalStage s) {
    // Looks right, then left, then turns to the child.
    final turn = (s.t * 3).floor().clamp(0, 2);
    s.koba(
      s.kobaAt,
      front: turn == 2,
      mirror: turn == 1,
      face: turn == 2 ? RobotFace.cheer : RobotFace.normal,
      size: turn == 2 ? s.u * 0.5 : null,
      gaze: turn == 2 ? Offset.zero : const Offset(8, -10),
    );
  }
}

/// Step by step: stars lie on stepping stones along a winding path, and
/// Koba hops from stone to stone in order, collecting each star.
class SequencingArrival extends ArrivalScene {
  const SequencingArrival() : super('sequencing');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalSequencing;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalSequencingKoba;

  /// The stones after Koba's spot: across the box, and how far in front
  /// of the hill's top (in the scene's unit), winding nearer and back.
  static const _stones = [
    (0.5, 0.07),
    (0.63, 0.015),
    (0.76, 0.075),
    (0.9, 0.02),
  ];

  List<Offset> _path(ArrivalStage s) => [
    s.kobaAt,
    for (final (fx, near) in _stones) s.on(fx) + Offset(0, near * s.u),
  ];

  /// When, in Koba's beat, each hop lands.
  static double _landsAt(int i) => 0.2 * (i + 1);

  @override
  List<(double, SoundEffect)> get effects => [
    for (var i = 0; i < _stones.length; i++) (_landsAt(i), SoundEffect.star),
  ];

  @override
  void paintPlanet(ArrivalStage s) {
    paintObstacle(s.canvas, theme.obstacle, s.on(0.97), s.u * 0.18);
    paintObstacle(s.canvas, theme.obstacle, s.on(0.7), s.u * 0.12, seed: 5);
    // The winding path, dotted from stone to stone.
    final points = _path(s);
    final dots = Paint()..color = theme.floor.withValues(alpha: 0.8);
    for (var i = 0; i + 1 < points.length; i++) {
      for (var k = 1; k < 6; k++) {
        final p = k / 6;
        final c =
            Offset.lerp(points[i], points[i + 1], p)! +
            Offset(0, -sin(pi * p) * s.u * 0.01);
        s.canvas.drawCircle(c, s.u * 0.008, dots);
      }
    }
    for (var i = 0; i < _stones.length; i++) {
      final c = points[i + 1];
      final stone = Rect.fromCenter(
        center: c,
        width: s.u * 0.15,
        height: s.u * 0.05,
      );
      s.canvas
        ..drawOval(stone, Paint()..color = theme.floor)
        ..drawOval(
          stone,
          Paint()
            ..color = storyInk
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, s.u * 0.006),
        );
      // Each star waits over its stone until Koba lands there.
      final taken = s.frame.beat == 1 ? (s.t - _landsAt(i)) / 0.12 : -1.0;
      if (taken >= 1) continue;
      final pop = taken > 0 ? taken : 0.0;
      paintStoryStar(
        s.canvas,
        c + Offset(0, -s.u * (0.12 + 0.02 * sin(s.time * 3 + i) + 0.1 * pop)),
        s.u * 0.04 * (1 + pop),
        opacity: 1 - pop,
        turn: s.time + i,
      );
    }
  }

  @override
  void paintKobaBeat(ArrivalStage s) {
    final points = _path(s);
    final hop = (s.t / 0.2).floor();
    if (hop >= _stones.length) {
      s.koba(points.last, face: RobotFace.cheer, size: s.u * 0.3);
      return;
    }
    final p = Curves.easeInOut.transform(s.t / 0.2 - hop);
    final base =
        Offset.lerp(points[hop], points[hop + 1], p)! +
        Offset(0, -sin(pi * p) * s.u * 0.1);
    s.koba(
      base,
      size: hop == 0 ? storyLerp(s.kobaSize, s.u * 0.3, p) : s.u * 0.3,
    );
  }
}

/// Loops: the path climbs in steps that are all the same, and Koba climbs
/// them one by one, then wonders about a shortcut: the repeat block's sign.
class LoopsArrival extends ArrivalScene {
  const LoopsArrival() : super('loops');

  @override
  String sceneWords(AppLocalizations l10n) => l10n.storyArrivalLoops;

  @override
  String kobaWords(AppLocalizations l10n) => l10n.storyArrivalLoopsKoba;

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
