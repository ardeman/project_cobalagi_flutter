import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/features/play/view/world/world_theme.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/arrival_scenes.dart';
import 'package:cobalagi/features/story/view/star_ship.dart';
import 'package:cobalagi/features/story/view/story_paint.dart';
import 'package:cobalagi/learning/story.dart';

/// How full the tank is before the last stars fly in, in the endings, and
/// after the space wind blew a few out, in the new planet scene.
const _almostFull = 0.85;

/// The story's ending (about 15 seconds), when the child has finished every
/// planet, [lastPlanet] the last: the ship takes off from it as the last
/// stars fly into the tank, does a happy loop while Koba thanks the
/// commander, and flies among every planet the child explored.
class EndingScene extends StoryScene {
  const EndingScene(this.lastPlanet);

  final String lastPlanet;

  @override
  String get id => Story.fullTank(lastPlanet);

  @override
  List<StoryBeat> get beats => [
    StoryBeat(
      clip: VoiceClips.storyEnding,
      words: (l10n) => l10n.storyEnding,
      length: const Duration(milliseconds: 5000),
      effects: const [
        (0.08, SoundEffect.shipLaunch),
        (0.55, SoundEffect.star),
        (0.8, SoundEffect.star),
      ],
    ),
    StoryBeat(
      clip: VoiceClips.storyEndingKoba,
      words: (l10n) => l10n.storyEndingKoba,
      length: const Duration(milliseconds: 5000),
      effects: const [(0.1, SoundEffect.goal)],
    ),
    StoryBeat(
      clip: VoiceClips.storyEndingMore,
      words: (l10n) => l10n.storyEndingMore,
      length: const Duration(milliseconds: 5000),
      effects: const [(0, SoundEffect.shipFly)],
    ),
  ];

  @override
  void paint(Canvas canvas, Rect stage, StoryFrame frame, StoryArt? art) {
    final (box, u) = storyBox(stage);
    final t = frame.t;
    final time = frame.time;
    switch (frame.beat) {
      case 0:
        // The ship lifts off the last planet; the last stars fly in.
        final theme = WorldTheme.forConcept(lastPlanet);
        final ground = box.top + box.height * 0.9;
        final sink = Curves.easeIn.transform(((t - 0.3) / 0.7).clamp(0, 1));
        // The planet falls away behind the ship, getting smaller.
        final away = 1 - 0.8 * sink;
        canvas
          ..save()
          ..translate(box.center.dx, ground)
          ..scale(away)
          ..translate(-box.center.dx, -ground);
        paintGround(canvas, box, ground + sink * u * 0.3, theme: theme);
        canvas.restore();
        final rise = Curves.easeInOut.transform((t / 0.8).clamp(0, 1));
        final base = Offset(
          box.center.dx,
          storyLerp(ground, box.top + box.height * 0.6, rise),
        );
        if (art != null) {
          paintShip(
            canvas,
            art,
            t < 0.1 ? ShipView.landed : ShipView.launch,
            base: base,
            size: u * 0.8,
            fill: storyLerp(_almostFull, 1, ((t - 0.4) / 0.5).clamp(0, 1)),
            face: RobotFace.cheer,
            time: time,
          );
        }
        _starsIn(
          canvas,
          box,
          u,
          tankPoint(ShipView.launch, base: base, size: u * 0.8),
          ((t - 0.3) / 0.6).clamp(0, 1),
          time,
        );
      case 1:
        _happyLoop(canvas, box, u, t, time, art);
      default:
        // Among every planet explored, each with its star back.
        final planets = VoiceClips.arrivalConcepts;
        for (var i = 0; i < planets.length; i++) {
          final a = -pi / 2 + i * 2 * pi / planets.length + time * 0.08;
          final c =
              box.center +
              Offset(cos(a) * box.width * 0.4, sin(a) * box.height * 0.38);
          paintPlanet(
            canvas,
            c,
            u * 0.06,
            WorldTheme.forConcept(planets[i]).ground,
          );
          paintStoryStar(
            canvas,
            c - Offset(0, u * 0.1),
            u * 0.025,
            opacity: 0.6 + 0.4 * sin(time * 3 + i),
            turn: time + i,
          );
        }
        if (art != null) {
          paintShip(
            canvas,
            art,
            ShipView.flying,
            base: box.center + Offset(0, sin(time * 2.4) * u * 0.03),
            size: u * 0.7,
            fill: 1,
            face: RobotFace.cheer,
            time: time,
          );
        }
    }
  }
}

/// The short ending (about 9 seconds) after planets added in an update are
/// finished, [lastPlanet] the newest: the stars fly home into the tank, the
/// ship does a happy loop, and Koba thanks the commander for its skill.
class FullAgainScene extends StoryScene {
  const FullAgainScene(this.lastPlanet);

  final String lastPlanet;

  @override
  String get id => Story.fullTank(lastPlanet);

  @override
  List<StoryBeat> get beats => [
    StoryBeat(
      clip: VoiceClips.storyFullAgain,
      words: (l10n) => l10n.storyFullAgain,
      length: const Duration(milliseconds: 4000),
      effects: const [
        (0, SoundEffect.shipFly),
        (0.5, SoundEffect.star),
        (0.75, SoundEffect.star),
      ],
    ),
    StoryBeat(
      clip: VoiceClips.storyThanks(lastPlanet),
      words: (l10n) =>
          arrivalScenes[lastPlanet]?.thanksWords(l10n) ?? l10n.storyEndingKoba,
      length: const Duration(milliseconds: 5000),
      effects: const [(0.1, SoundEffect.goal)],
    ),
  ];

  @override
  void paint(Canvas canvas, Rect stage, StoryFrame frame, StoryArt? art) {
    final (box, u) = storyBox(stage);
    final time = frame.time;
    if (frame.beat == 1) {
      _happyLoop(canvas, box, u, frame.t, time, art);
      return;
    }
    final t = frame.t;
    paintPlanet(
      canvas,
      box.topLeft + Offset(box.width * 0.85, box.height * 0.25),
      u * 0.08,
      WorldTheme.forConcept(lastPlanet).ground,
    );
    final base = box.center + Offset(0, sin(time * 2.4) * u * 0.02);
    if (art != null) {
      paintShip(
        canvas,
        art,
        ShipView.flying,
        base: base,
        size: u * 0.8,
        fill: storyLerp(_almostFull, 1, ((t - 0.3) / 0.6).clamp(0, 1)),
        face: RobotFace.cheer,
        time: time,
      );
    }
    _starsIn(
      canvas,
      box,
      u,
      tankPoint(ShipView.flying, base: base, size: u * 0.8),
      (t / 0.85).clamp(0, 1),
      time,
    );
  }
}

/// For a child who saw an ending when an update brings new planets (about
/// 10 seconds): the space wind blows a few stars out of the full tank to a
/// planet nobody had found yet, and Koba asks the commander for help again.
class NewPlanetScene extends StoryScene {
  const NewPlanetScene(this.lastPlanet);

  /// The newest planet.
  final String lastPlanet;

  @override
  String get id => Story.newPlanet(lastPlanet);

  @override
  List<StoryBeat> get beats => [
    StoryBeat(
      clip: VoiceClips.storyNewPlanet,
      words: (l10n) => l10n.storyNewPlanet,
      length: const Duration(milliseconds: 6000),
      effects: const [(0.05, SoundEffect.wind)],
    ),
    StoryBeat(
      clip: VoiceClips.storyNewPlanetKoba,
      words: (l10n) => l10n.storyNewPlanetKoba,
      length: const Duration(milliseconds: 4500),
      effects: const [(0.3, SoundEffect.star)],
    ),
  ];

  @override
  void paint(Canvas canvas, Rect stage, StoryFrame frame, StoryArt? art) {
    final (box, u) = storyBox(stage);
    final t = frame.t;
    final time = frame.time;
    final planet = box.topLeft + Offset(box.width * 0.86, box.height * 0.3);
    final colour = WorldTheme.forConcept(lastPlanet).ground;
    final base =
        box.topLeft +
        Offset(box.width * 0.36, box.height * 0.6) +
        Offset(0, sin(time * 2.4) * u * 0.02);
    if (frame.beat == 0) {
      final gust = sin(pi * t);
      final angle = -0.1 * gust * sin(time * 7);
      final out = Curves.easeInOut.transform(((t - 0.2) / 0.6).clamp(0, 1));
      // The planet nobody had found yet shows as the stars reach it.
      paintPlanet(canvas, planet, u * 0.09 * out, colour);
      if (art != null) {
        paintShip(
          canvas,
          art,
          ShipView.flying,
          base: base,
          size: u * 0.8,
          angle: angle,
          fill: storyLerp(1, _almostFull, out),
          face: t > 0.25 ? RobotFace.dizzy : RobotFace.normal,
          time: time,
        );
      }
      final tank = tankPoint(
        ShipView.flying,
        base: base,
        size: u * 0.8,
        angle: angle,
      );
      for (var i = 0; i < 3; i++) {
        final p = ((t - 0.2 - i * 0.08) / 0.5).clamp(0.0, 1.0);
        if (p == 0) continue;
        final to = planet + Offset(u * (0.06 * i - 0.06), -u * 0.13);
        paintStoryStar(
          canvas,
          Offset.lerp(tank, to, Curves.easeOut.transform(p))! +
              Offset(0, -sin(pi * p) * u * 0.15),
          u * 0.035,
          turn: time * 4 + i,
        );
      }
      paintWind(canvas, box, u, time, gust);
      return;
    }
    // The new planet glows, its stars waiting, and Koba asks for help.
    canvas.drawCircle(
      planet,
      u * 0.16,
      Paint()
        ..color = storyGold.withValues(alpha: 0.25 + 0.1 * sin(time * 3))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.05),
    );
    paintPlanet(canvas, planet, u * 0.09, colour);
    for (var i = 0; i < 3; i++) {
      paintStoryStar(
        canvas,
        planet + Offset(u * (0.06 * i - 0.06), -u * 0.13),
        u * 0.03,
        opacity: 0.7 + 0.3 * sin(time * 3 + i),
        turn: time + i,
      );
    }
    if (art != null) {
      paintShip(
        canvas,
        art,
        ShipView.flying,
        base: base,
        size: u * 0.8,
        angle: -0.15 * Curves.easeOut.transform((t / 0.3).clamp(0, 1)),
        fill: _almostFull,
        face: RobotFace.cheer,
        time: time,
      );
    }
  }
}

/// Stars flying in from all round into the tank at [tank], [p] (0 to 1)
/// through.
void _starsIn(
  Canvas canvas,
  Rect box,
  double u,
  Offset tank,
  double p,
  double time,
) {
  for (var i = 0; i < 8; i++) {
    final q = ((p - i * 0.06) / 0.5).clamp(0.0, 1.0);
    if (q == 0 || q == 1) continue;
    final a = i * 2 * pi / 8 + 0.4;
    final from =
        box.center +
        Offset(cos(a) * box.width * 0.6, sin(a) * box.height * 0.6);
    paintStoryStar(
      canvas,
      Offset.lerp(from, tank, Curves.easeIn.transform(q))!,
      u * 0.035 * (1 - 0.5 * q),
      turn: time * 4 + i,
    );
  }
}

/// The full ship doing a happy loop, a trail of sparkles behind, [t] (0 to
/// 1) through.
void _happyLoop(
  Canvas canvas,
  Rect box,
  double u,
  double t,
  double time,
  StoryArt? art,
) {
  final radius = u * 0.22;
  final centre = box.center - Offset(0, u * 0.05);
  Offset at(double a) => centre + Offset(sin(a), cos(a)) * radius;
  final a = 2 * pi * Curves.easeInOut.transform((t / 0.8).clamp(0, 1));
  for (var i = 1; i <= 6; i++) {
    final back = a - i * 0.25;
    if (back < 0) break;
    paintStoryStar(
      canvas,
      at(back),
      u * 0.022,
      opacity: 1 - i / 7,
      turn: time * 3 + i,
    );
  }
  if (art != null) {
    paintShip(
      canvas,
      art,
      ShipView.flying,
      base: at(a),
      size: u * 0.7,
      angle: -a,
      fill: 1,
      face: RobotFace.cheer,
      time: time,
    );
  }
}
