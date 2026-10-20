import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/view/star_ship.dart';

/// The map's celebration of a finished planet: Koba's ship takes off from
/// it, the planet's stars fly into its tank (from [fillFrom] to [fillTo]
/// full), and it flies along the path to the next planet and lands there,
/// which then calls [onLanded]. Placed over the map in its coordinates;
/// [from] and [to] are the planets' centres as the map lays them out.
class ShipFlight extends StatefulWidget {
  const ShipFlight({
    super.key,
    required this.from,
    required this.to,
    required this.islandSize,
    required this.fillFrom,
    required this.fillTo,
    required this.onLanded,
  });

  final Offset from;
  final Offset to;
  final double islandSize;
  final double fillFrom;
  final double fillTo;
  final VoidCallback onLanded;

  /// How long the flight takes, from take-off to landing and fading away.
  static const duration = Duration(milliseconds: 7000);

  @override
  State<ShipFlight> createState() => _ShipFlightState();
}

class _ShipFlightState extends State<ShipFlight>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: ShipFlight.duration,
  );
  StoryArt? _art;
  var _landed = false;

  /// Sounds by when they play, as a share of the flight.
  static const _sounds = [
    (0.2, SoundEffect.star),
    (0.27, SoundEffect.star),
    (0.34, SoundEffect.star),
    (_landAt, SoundEffect.goal),
  ];

  /// When the ship touches down on the next planet.
  static const _landAt = 0.86;
  var _last = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_tick);
    StoryArt.load().then(
      (art) {
        if (!mounted) return;
        setState(() => _art = art);
        context.read<AudioService>().playVoice(
          VoiceClips.storyFly,
          languageCode: Localizations.localeOf(context).languageCode,
        );
        _controller.forward();
      },
      // Without its pictures the planet opens at once.
      onError: (Object _) => _land(),
    );
  }

  void _tick() {
    final v = _controller.value;
    for (final (at, effect) in _sounds) {
      if (_last < at && v >= at) {
        context.read<AudioService>().playEffect(effect);
      }
    }
    _last = v;
    if (v >= _landAt) _land();
  }

  void _land() {
    if (_landed || !mounted) return;
    _landed = true;
    widget.onLanded();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _FlightPainter(
        progress: _controller,
        art: _art,
        from: widget.from,
        to: widget.to,
        size: widget.islandSize,
        fillFrom: widget.fillFrom,
        fillTo: widget.fillTo,
      ),
    ),
  );
}

class _FlightPainter extends CustomPainter {
  _FlightPainter({
    required this.progress,
    required this.art,
    required this.from,
    required this.to,
    required this.size,
    required this.fillFrom,
    required this.fillTo,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final StoryArt? art;
  final Offset from;
  final Offset to;
  final double size;
  final double fillFrom;
  final double fillTo;

  /// The top of a planet whose map centre is [c] (see the map's `_Island`).
  Offset _top(Offset c) => c - Offset(0, size * 0.8);

  @override
  void paint(Canvas canvas, Size _) {
    final art = this.art;
    if (art == null) return;
    final v = progress.value;
    final picture = size * 1.6;
    final hover = size * 0.55;
    final start = _top(from);
    final end = _top(to);
    final up = start - Offset(0, hover);
    final over = end - Offset(0, hover);
    double part(double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);
    final time = v * ShipFlight.duration.inMilliseconds / 1000;
    final bob = Offset(0, sin(time * 3) * size * 0.03);

    if (v < 0.4) {
      // Lifts off, then hovers while the planet's stars fly into the tank.
      final lift = Curves.easeInOut.transform(part(0, 0.14));
      final base = Offset.lerp(start, up, lift)! + (lift == 1 ? bob : .zero);
      final collect = part(0.14, 0.4);
      paintShip(
        canvas,
        art,
        ShipView.launch,
        base: base,
        size: picture,
        fill: fillFrom + (fillTo - fillFrom) * part(0.16, 0.38),
        face: collect > 0 ? RobotFace.cheer : RobotFace.normal,
        time: time,
      );
      final tank = tankPoint(ShipView.launch, base: base, size: picture);
      for (var i = 0; i < 8; i++) {
        final p = ((collect - i * 0.06) / 0.5).clamp(0.0, 1.0);
        if (p <= 0 || p >= 1) continue;
        final a = i * 2 * pi / 8;
        final out =
            from - Offset(0, size * 0.42) + Offset(cos(a), sin(a)) * size;
        final at =
            Offset.lerp(out, tank, Curves.easeIn.transform(p))! +
            Offset(sin(pi * p) * size * 0.2, 0);
        _star(canvas, at, size * 0.09 * (1 - 0.5 * p), time * 3 + i);
      }
    } else if (v < 0.75) {
      // Flies in an arc along the path to the next planet, nose first.
      final p = Curves.easeInOut.transform(part(0.4, 0.75));
      final control = (up + over) / 2 - Offset(0, size * 0.6);
      final base = _bezier(up, control, over, p);
      final heading = _bezier(up, control, over, min(1, p + 0.01)) - base;
      final left = (over - up).dx < 0;
      // The picture flies nose up and to the right by itself.
      final raw = atan2(heading.dy, left ? -heading.dx : heading.dx) + 0.4;
      final angle = raw.clamp(-0.6, 0.9) * (left ? -1 : 1);
      paintShip(
        canvas,
        art,
        ShipView.flying,
        base: base,
        size: picture,
        angle: angle,
        mirror: left,
        fill: fillTo,
        face: RobotFace.cheer,
        time: time,
      );
    } else {
      // Comes down on the planet, then fades as the planet opens.
      final down = Curves.easeOut.transform(
        part(0.75, _ShipFlightState._landAt),
      );
      final landed = v >= _ShipFlightState._landAt;
      paintShip(
        canvas,
        art,
        landed ? ShipView.landed : ShipView.landing,
        base: Offset.lerp(over, end, down)!,
        size: picture,
        fill: fillTo,
        face: landed ? RobotFace.cheer : RobotFace.normal,
        time: time,
        opacity: 1 - part(0.93, 1),
      );
    }
  }

  @override
  bool shouldRepaint(_FlightPainter old) =>
      old.art != art ||
      old.from != from ||
      old.to != to ||
      old.size != size ||
      old.fillFrom != fillFrom ||
      old.fillTo != fillTo;
}

Offset _bezier(Offset a, Offset c, Offset b, double t) =>
    a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);

void _star(Canvas canvas, Offset c, double r, double turn) {
  final path = starPath(c, r, turn: turn * 0.3);
  canvas
    ..drawPath(path, Paint()..color = const Color(0xFFFFC83D))
    ..drawPath(
      path,
      Paint()
        ..color = const Color(0xFF222244)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18
        ..strokeJoin = StrokeJoin.round,
    );
}
