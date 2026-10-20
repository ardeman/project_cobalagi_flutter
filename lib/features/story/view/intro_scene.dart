import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/data/story_scene.dart';
import 'package:cobalagi/features/story/view/star_ship.dart';
import 'package:cobalagi/features/story/view/story_paint.dart';
import 'package:cobalagi/learning/story.dart';

/// The story's intro (about 25 seconds): Koba flies happily on a full tank,
/// a space wind scatters the stars over the planets, the ship lands, Koba
/// bumps into a rock and tries again, and asks the child for help.
class IntroScene extends StoryScene {
  const IntroScene();

  @override
  String get id => Story.intro;

  @override
  List<StoryBeat> get beats => [
    StoryBeat(
      clip: VoiceClips.storyIntroFly,
      words: (l10n) => l10n.storyIntroFly,
      length: const Duration(milliseconds: 5000),
    ),
    StoryBeat(
      clip: VoiceClips.storyIntroWind,
      words: (l10n) => l10n.storyIntroWind,
      length: const Duration(milliseconds: 5000),
    ),
    StoryBeat(
      clip: VoiceClips.storyIntroLand,
      words: (l10n) => l10n.storyIntroLand,
      length: const Duration(milliseconds: 4500),
    ),
    StoryBeat(
      clip: VoiceClips.storyIntroBump,
      words: (l10n) => l10n.storyIntroBump,
      length: const Duration(milliseconds: 5500),
      effects: const [(_bumpAt, SoundEffect.bumpRock)],
    ),
    StoryBeat(
      clip: VoiceClips.storyIntroHelp,
      words: (l10n) => l10n.storyIntroHelp,
      length: const Duration(milliseconds: 5000),
      effects: const [(0.25, SoundEffect.star)],
    ),
  ];

  /// When, in the bump beat, Koba reaches the rock.
  static const _bumpAt = 0.3;

  @override
  void paint(Canvas canvas, Rect stage, StoryFrame frame, StoryArt? art) {
    final (box, u) = storyBox(stage);
    Offset at(double x, double y) =>
        box.topLeft + Offset(x * box.width, y * box.height);
    final t = frame.t;
    final time = frame.time;
    final shipSize = u * 0.9;
    final ground = at(0, 0.9).dy;

    switch (frame.beat) {
      case 0:
        // Flying in on a full tank, a trail of sparkles behind.
        final x = storyLerp(-0.3, 0.5, Curves.easeOutCubic.transform(t));
        final base = at(x, 0.62) + Offset(0, sin(time * 2.4) * u * 0.02);
        for (var i = 1; i <= 5; i++) {
          paintStoryStar(
            canvas,
            base - Offset(u * 0.1 * i, -u * 0.03 * sin(time * 3 + i)),
            u * 0.025,
            opacity: 1 - i / 6,
            turn: time + i,
          );
        }
        if (art != null) {
          paintShip(
            canvas,
            art,
            ShipView.flying,
            base: base,
            size: shipSize,
            fill: 1,
            face: RobotFace.cheer,
            time: time,
          );
        }
      case 1:
        // The wind: streaks blow across, the ship rocks, and the stars fly
        // out of its tank to the planets far away.
        final gust = sin(pi * t);
        paintPlanet(canvas, at(0.06, 0.18), u * 0.07, const Color(0xFF8E6CFF));
        paintPlanet(canvas, at(0.16, 0.86), u * 0.09, const Color(0xFF3FC5E8));
        paintPlanet(canvas, at(0.92, 0.12), u * 0.05, const Color(0xFFFF7AB6));
        final base = at(0.55, 0.62) + Offset(0, sin(time * 2.4) * u * 0.02);
        final angle = -0.12 * gust * sin(time * 7);
        final tank = tankPoint(
          ShipView.flying,
          base: base,
          size: shipSize,
          angle: angle,
        );
        if (art != null) {
          paintShip(
            canvas,
            art,
            ShipView.flying,
            base: base,
            size: shipSize,
            angle: angle,
            fill: 1 - Curves.easeInOut.transform(t),
            face: t > 0.25 ? RobotFace.dizzy : RobotFace.normal,
            time: time,
          );
        }
        for (var i = 0; i < 10; i++) {
          final p = ((t - i * 0.06) / 0.35).clamp(0.0, 1.0);
          if (p == 0) continue;
          final target = at(
            i.isEven ? -0.1 + 0.04 * i : 0.1 + 0.03 * i,
            0.05 + 0.09 * i,
          );
          final c = Offset.lerp(tank, target, Curves.easeOut.transform(p))!;
          // Each star arcs a little as the wind carries it.
          paintStoryStar(
            canvas,
            c + Offset(0, -sin(pi * p) * u * 0.12),
            u * 0.035,
            turn: time * 4 + i,
          );
        }
        paintWind(canvas, box, u, time, gust);
      case 2:
        // Out of stars, the ship comes down on a planet.
        final rise = Curves.easeOutCubic.transform((t / 0.4).clamp(0, 1));
        final surface = storyLerp(box.bottom + u * 0.5, ground, rise);
        paintGround(canvas, box, surface);
        final down = (t / 0.75).clamp(0.0, 1.0);
        final x = at(0.3, 0).dx;
        final landed = t >= 0.75;
        final base = Offset(
          x,
          storyLerp(box.top - u * 0.2, ground, Curves.easeOut.transform(down)),
        );
        if (landed) paintDust(canvas, base, u, (t - 0.75) / 0.25);
        if (art != null) {
          paintShip(
            canvas,
            art,
            landed ? ShipView.landed : ShipView.landing,
            base: base,
            size: shipSize,
            time: time,
          );
        }
      case 3:
        // Koba rolls out, bumps into a rock, backs up and goes round it,
        // passing in front of it (nearer the child).
        paintGround(canvas, box, ground);
        if (art != null) {
          paintShip(
            canvas,
            art,
            ShipView.landed,
            base: Offset(at(0.3, 0).dx, ground),
            size: shipSize,
            koba: false,
            time: time,
          );
        }
        final rock = Offset(at(0.66, 0).dx, ground);
        final touch = rock.dx - u * 0.17;
        double x;
        var near = 0.0;
        var face = RobotFace.normal;
        var roll = true;
        if (t < _bumpAt) {
          x = storyLerp(
            at(0.38, 0).dx,
            touch,
            Curves.easeIn.transform(t / _bumpAt),
          );
        } else if (t < 0.55) {
          // Bump: it bounces back and spins dizzy.
          final p = (t - _bumpAt) / (0.55 - _bumpAt);
          x = touch - u * 0.1 * Curves.easeOut.transform(p);
          face = RobotFace.dizzy;
          roll = false;
        } else {
          // Tries again: round the front of the rock and on.
          final p = Curves.easeInOut.transform((t - 0.55) / 0.45);
          x = storyLerp(touch - u * 0.1, rock.dx + u * 0.3, p);
          near = sin(pi * p);
          face = p > 0.75 ? RobotFace.cheer : RobotFace.normal;
        }
        paintRock(canvas, rock, u);
        if (art != null) {
          paintKoba(
            canvas,
            art,
            base: Offset(x, ground + near * u * 0.08),
            size: u * 0.42 * (1 + 0.1 * near),
            face: face,
            time: time,
            angle: roll ? 0.05 * sin(time * 14) : 0,
          );
        }
      default:
        // Koba turns to the child and asks for help, under the scattered
        // stars.
        paintGround(canvas, box, ground);
        for (var i = 0; i < 6; i++) {
          paintStoryStar(
            canvas,
            at(0.1 + 0.16 * i, 0.12 + 0.08 * (i % 3)),
            u * 0.03,
            opacity: 0.5 + 0.4 * sin(time * 2 + i),
            turn: i.toDouble(),
          );
        }
        paintRock(canvas, Offset(at(0.9, 0).dx, ground), u * 0.8);
        if (art != null) {
          paintShip(
            canvas,
            art,
            ShipView.landed,
            base: Offset(at(0.25, 0).dx, ground),
            size: shipSize,
            koba: false,
            time: time,
          );
          final hop = sin(pi * (t / 0.3).clamp(0.0, 1.0));
          paintKoba(
            canvas,
            art,
            base: Offset(at(0.62, 0).dx, ground - hop * u * 0.06),
            size: u * 0.55,
            face: RobotFace.cheer,
            time: time,
            front: true,
          );
        }
    }
  }
}
