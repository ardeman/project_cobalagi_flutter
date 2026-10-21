import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/view/star_ship.dart';

/// Where Koba's ship stands when landed on a planet whose map centre is
/// [centre]: on the right of the planet's piece (see the map's `_Island`),
/// beside the concept's emblem.
Offset parkedShipBase(Offset centre, double islandSize) =>
    centre + Offset(islandSize * 0.48, -islandSize * 0.1);

/// How big the landed ship's picture is on the map.
double parkedShipSize(double islandSize) => islandSize * 1.1;

/// Koba's ship landed on the planet the child is on, at [centre] on the map,
/// its tank [fill] full. Placed over the map in its coordinates, like
/// [ShipFlight]; still, so it never repaints.
class ParkedShip extends StatefulWidget {
  const ParkedShip({
    super.key,
    required this.centre,
    required this.islandSize,
    required this.fill,
    this.emblem,
  });

  final Offset centre;
  final double islandSize;
  final double fill;

  /// The commander's emblem on the ship's hull ([StoryArt.emblem]).
  final (IconData, Color)? emblem;

  @override
  State<ParkedShip> createState() => _ParkedShipState();
}

class _ParkedShipState extends State<ParkedShip> {
  StoryArt? _art;

  @override
  void initState() {
    super.initState();
    StoryArt.load().then(
      (art) {
        if (mounted) setState(() => _art = art.withEmblem(widget.emblem));
      },
      // Without its pictures the map shows no ship.
      onError: (Object _) {},
    );
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _ParkedPainter(
        art: _art,
        base: parkedShipBase(widget.centre, widget.islandSize),
        size: parkedShipSize(widget.islandSize),
        fill: widget.fill,
      ),
    ),
  );
}

class _ParkedPainter extends CustomPainter {
  const _ParkedPainter({
    required this.art,
    required this.base,
    required this.size,
    required this.fill,
  });

  final StoryArt? art;
  final Offset base;
  final double size;
  final double fill;

  @override
  void paint(Canvas canvas, Size _) {
    final art = this.art;
    if (art == null) return;
    paintShip(canvas, art, ShipView.landed, base: base, size: size, fill: fill);
  }

  @override
  bool shouldRepaint(_ParkedPainter old) =>
      old.art != art ||
      old.base != base ||
      old.size != size ||
      old.fill != fill;
}

/// The map's celebration of a finished planet: Koba's ship takes off from
/// where it stands ([parkedShipBase]), the planet's stars fly into its tank (from [fillFrom] to [fillTo]
/// full), and it flies along the path to the next planet and lands there,
/// which then calls [onLanded]. Placed over the map in its coordinates;
/// [from] and [to] are the planets' centres as the map lays them out.
///
/// [ShipFlight.hop] is the short trip to a planet the child opens, or back
/// to the current one: no stars, no voice, and it lands as it ends.
class ShipFlight extends StatefulWidget {
  const ShipFlight({
    super.key,
    required this.from,
    required this.to,
    required this.islandSize,
    required this.fillFrom,
    required this.fillTo,
    required this.onLanded,
    this.emblem,
  }) : _timeline = _FlightTimeline.celebrate;

  const ShipFlight.hop({
    super.key,
    required this.from,
    required this.to,
    required this.islandSize,
    required double fill,
    required this.onLanded,
    this.emblem,
  }) : fillFrom = fill,
       fillTo = fill,
       _timeline = _FlightTimeline.hop;

  final Offset from;
  final Offset to;
  final double islandSize;
  final double fillFrom;
  final double fillTo;
  final VoidCallback onLanded;

  /// The commander's emblem on the ship's hull ([StoryArt.emblem]).
  final (IconData, Color)? emblem;

  final _FlightTimeline _timeline;

  /// How long the flight takes, from take-off to landing and fading away.
  static const duration = Duration(milliseconds: 7000);

  /// How long a [ShipFlight.hop] takes, from take-off to landing.
  static const hopDuration = Duration(milliseconds: 2400);

  @override
  State<ShipFlight> createState() => _ShipFlightState();
}

class _ShipFlightState extends State<ShipFlight>
    with SingleTickerProviderStateMixin {
  late final _timeline = widget._timeline;
  late final _controller = AnimationController(
    vsync: this,
    duration: _timeline.duration,
  );
  StoryArt? _art;
  var _landed = false;
  var _last = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_tick);
    StoryArt.load().then(
      (art) {
        if (!mounted) return;
        setState(() => _art = art.withEmblem(widget.emblem));
        if (_timeline.collects) {
          context.read<AudioService>().playVoice(
            VoiceClips.storyFly,
            languageCode: Localizations.localeOf(context).languageCode,
          );
        }
        _controller.forward();
      },
      // Without its pictures the planet opens at once.
      onError: (Object _) => _land(),
    );
  }

  void _tick() {
    final v = _controller.value;
    for (final (at, effect) in _timeline.sounds) {
      if (_last < at && v >= at) {
        context.read<AudioService>().playEffect(effect);
      }
    }
    _last = v;
    if (v >= _timeline.landAt) _land();
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
        timeline: _timeline,
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
    required this.timeline,
    required this.art,
    required this.from,
    required this.to,
    required this.size,
    required this.fillFrom,
    required this.fillTo,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final _FlightTimeline timeline;
  final StoryArt? art;
  final Offset from;
  final Offset to;
  final double size;
  final double fillFrom;
  final double fillTo;

  @override
  void paint(Canvas canvas, Size _) {
    final art = this.art;
    if (art == null) return;
    final v = progress.value;
    final picture = size * 1.6;
    final hover = size * 0.55;
    final parked = parkedShipSize(size);
    final start = parkedShipBase(from, size);
    final end = parkedShipBase(to, size);
    final up = start - Offset(0, hover);
    final over = end - Offset(0, hover);
    double part(double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);
    final t = timeline;
    final time = v * t.duration.inMilliseconds / 1000;
    final bob = Offset(0, sin(time * 3) * size * 0.03);

    if (v < t.flyFrom) {
      // Lifts off, then hovers while the planet's stars fly into the tank.
      final lift = Curves.easeInOut.transform(part(0, t.liftTo));
      final base = Offset.lerp(start, up, lift)! + (lift == 1 ? bob : .zero);
      // It grows from its size on the planet as it lifts off.
      final big = parked + (picture - parked) * lift;
      final collect = t.collects ? part(t.liftTo, t.flyFrom) : 0.0;
      paintShip(
        canvas,
        art,
        ShipView.launch,
        base: base,
        size: big,
        fill: fillFrom + (fillTo - fillFrom) * part(0.16, 0.38),
        face: collect > 0 ? RobotFace.cheer : RobotFace.normal,
        time: time,
      );
      final tank = tankPoint(ShipView.launch, base: base, size: big);
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
    } else if (v < t.flyTo) {
      // Flies in an arc along the path to the next planet, nose first.
      final p = Curves.easeInOut.transform(part(t.flyFrom, t.flyTo));
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
      final down = Curves.easeOut.transform(part(t.flyTo, t.landAt));
      final landed = v >= t.landAt;
      paintShip(
        canvas,
        art,
        landed ? ShipView.landed : ShipView.landing,
        base: Offset.lerp(over, end, down)!,
        // Down to its size on the planet, where [ParkedShip] takes over.
        size: picture + (parked - picture) * down,
        fill: fillTo,
        face: landed ? RobotFace.cheer : RobotFace.normal,
        time: time,
        opacity: t.landAt < 1 ? 1 - part(0.93, 1) : 1,
      );
    }
  }

  @override
  bool shouldRepaint(_FlightPainter old) =>
      old.art != art ||
      old.timeline != timeline ||
      old.from != from ||
      old.to != to ||
      old.size != size ||
      old.fillFrom != fillFrom ||
      old.fillTo != fillTo;
}

/// When each part of a [ShipFlight] happens, as a share of its [duration]:
/// the lift-off ends at [liftTo], the flight runs from [flyFrom] to [flyTo],
/// and the ship touches down at [landAt].
enum _FlightTimeline {
  celebrate(
    duration: ShipFlight.duration,
    collects: true,
    liftTo: 0.14,
    flyFrom: 0.4,
    flyTo: 0.75,
    landAt: 0.86,
    sounds: [
      (0.2, SoundEffect.star),
      (0.27, SoundEffect.star),
      (0.34, SoundEffect.star),
      (0.86, SoundEffect.goal),
    ],
  ),
  hop(
    duration: ShipFlight.hopDuration,
    collects: false,
    liftTo: 0.2,
    flyFrom: 0.22,
    flyTo: 0.8,
    landAt: 1,
    sounds: [],
  );

  const _FlightTimeline({
    required this.duration,
    required this.collects,
    required this.liftTo,
    required this.flyFrom,
    required this.flyTo,
    required this.landAt,
    required this.sounds,
  });

  final Duration duration;

  /// Whether the planet's stars fly into the tank while the ship hovers.
  final bool collects;
  final double liftTo;
  final double flyFrom;
  final double flyTo;
  final double landAt;

  /// Sounds by when they play, as a share of the flight.
  final List<(double, SoundEffect)> sounds;
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
