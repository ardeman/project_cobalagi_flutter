import 'dart:math' show pi;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show IconData;

import '../../../../engine/world/direction.dart';
import 'world_components.dart' show standUp;

/// One step of a hint, drawn on the map like the block that makes it: its
/// colour and picture. Holds no game logic; the play view decides what each
/// step is.
final class HintMark {
  const HintMark({
    required this.at,
    required this.icon,
    required this.color,
    this.label,
    this.labelFont,
    this.badge,
    this.faded = false,
    this.big = false,
    this.loop,
    this.heading,
  });

  /// Where the mark sits, in tiles (0.5 is a tile's centre).
  final Vector2 at;
  final IconData icon;
  final Color color;

  /// A small number on the mark, such as how many steps a Step Box holds.
  final String? label;

  /// The app's text font for [label]; the world has no theme of its own.
  final String? labelFont;

  /// A small badge in the bottom-left corner, as on the block: the Step Box
  /// on a "use steps" move.
  final ({IconData icon, Color color})? badge;

  /// Drawn see-through: a step the pattern hint says comes again.
  final bool faded;

  /// Drawn larger (1.6 times): the loop block that the pattern hint
  /// suggests.
  final bool big;

  /// A block the pattern hint puts inside the loop: ringed in the loop
  /// block's colour, so it stands apart from blocks before or after it.
  final Color? loop;

  /// The way Koba is going on the board at this step: a move's arrow points
  /// that way, and a turn's arrow starts from it, so the marks follow the
  /// road. Null for a mark drawn the right way up, such as the loop block.
  final Direction? heading;
}

/// A [HintMark] drawn as a small block, styled like the editor's blocks: a
/// rounded square with the block's gradient, soft rim and shadow, and its
/// white picture turned to follow the road.
class HintMarkComponent extends PositionComponent {
  HintMarkComponent(this.mark, {this.followRoad = true})
    : super(position: mark.at, size: Vector2.all(_size), anchor: Anchor.center);

  final HintMark mark;

  /// Whether the picture turns to [HintMark.heading]; off, it stays the
  /// right way up, exactly as on the block (a parent setting).
  final bool followRoad;

  static const _size = 0.46;

  /// The size the mark is drawn at before it is scaled down to [_size].
  static const _units = 100.0;

  static const _radius = Radius.circular(_units * 0.24);

  late final _fill = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(mark.color, const Color(0xFFFFFFFF), 0.18)!,
        mark.color,
        Color.lerp(mark.color, const Color(0xFF000000), 0.08)!,
      ],
    ).createShader(const Rect.fromLTWH(0, 0, _units, _units));
  static final _rim = Paint()
    ..color = const Color(0x59FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = _units * 0.07;
  static final _shadow = Paint()
    ..color = const Color(0x2E000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _units * 0.04);

  late final TextPainter _icon = _glyph(
    String.fromCharCode(mark.icon.codePoint),
    TextStyle(
      fontSize: 100,
      fontFamily: mark.icon.fontFamily,
      package: mark.icon.fontPackage,
      color: const Color(0xFFFFFFFF),
    ),
  );

  late final TextPainter? _badge = switch (mark.badge) {
    final badge? => _glyph(
      String.fromCharCode(badge.icon.codePoint),
      TextStyle(
        fontSize: 100,
        fontFamily: badge.icon.fontFamily,
        package: badge.icon.fontPackage,
        color: const Color(0xFFFFFFFF),
      ),
    ),
    null => null,
  };

  late final TextPainter? _label = mark.label == null
      ? null
      : _glyph(
          mark.label!,
          TextStyle(
            fontSize: 100,
            fontFamily: mark.labelFont,
            fontWeight: FontWeight.w900,
            height: 1,
            color: const Color(0xFF263238),
          ),
        );

  static TextPainter _glyph(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void render(Canvas canvas) {
    // A sign standing on its tile, like the pieces around it.
    standUp(canvas, const Offset(_size / 2, _size / 2));
    // Drawn in a box [_units] across and scaled down to the mark's size:
    // drawn at its real size (under half a tile), Android's renderer turns
    // the rounded corners and the loop ring into coarse, uneven curves.
    canvas.scale(_size / _units);
    if (mark.faded) {
      canvas.saveLayer(null, Paint()..color = const Color(0x5CFFFFFF));
    }
    _draw(canvas);
    if (mark.faded) canvas.restore();
  }

  void _draw(Canvas canvas) {
    final box = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, _units, _units),
      _radius,
    );
    // Inside the loop: a thick ring in the loop block's colour.
    if (mark.loop case final loop?) {
      canvas.drawRRect(
        box.inflate(_units * 0.1),
        Paint()
          ..color = loop
          ..style = PaintingStyle.stroke
          ..strokeWidth = _units * 0.1,
      );
    }
    canvas
      ..drawRRect(box.shift(const Offset(0, _units * 0.06)), _shadow)
      ..drawRRect(box, _fill)
      ..drawRRect(box.deflate(_units * 0.035), _rim);
    // The block's picture, turned to the way Koba is going on the screen
    // (the component itself is kept upright as the map turns).
    const glyph = _units * 0.6;
    canvas
      ..save()
      ..translate(_units / 2, _units / 2)
      ..rotate(switch (mark.heading) {
        final heading? when followRoad => heading.index * pi / 2 - angle,
        _ => 0,
      })
      ..scale(glyph / _icon.height)
      ..translate(-_icon.width / 2, -_icon.height / 2);
    _icon.paint(canvas, Offset.zero);
    canvas.restore();
    if ((mark.badge, _badge) case (final badge?, final glyph?)) {
      const r = _units * 0.1 / _size;
      const centre = Offset(_units * 0.24, _units * 0.76);
      canvas
        ..drawCircle(centre, r, Paint()..color = badge.color)
        ..drawCircle(
          centre,
          r,
          Paint()
            ..color = const Color(0xFFFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = _units * 0.025 / _size,
        )
        ..save()
        ..translate(centre.dx, centre.dy)
        ..scale(_units * 0.13 / _size / glyph.height)
        ..translate(-glyph.width / 2, -glyph.height / 2);
      glyph.paint(canvas, Offset.zero);
      canvas.restore();
    }
    if (_label case final label?) {
      // A white bubble on the corner holding the number, outlined in the
      // block's colour.
      const r = _units * 0.17 / _size;
      const centre = Offset(_units * 0.96, _units * 0.04);
      canvas
        ..drawCircle(centre, r, Paint()..color = const Color(0xFFFFFFFF))
        ..drawCircle(
          centre,
          r,
          Paint()
            ..color = mark.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = _units * 0.04 / _size,
        )
        ..save()
        ..translate(centre.dx, centre.dy)
        ..scale(_units * 0.26 / _size / label.height)
        ..translate(-label.width / 2, -label.height / 2);
      label.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }
}

/// The hint's route: dots along the tiles from the character to where
/// the route ends, drawn out over [drawIn] seconds as the blocks appear, so
/// the way shows even when the blocks are kept upright.
class HintTrailComponent extends PositionComponent {
  // Added before the hint's blocks, so it lies under them and over the floor.
  HintTrailComponent(this.points, {required this.drawIn});

  final List<Vector2> points;
  final double drawIn;
  var _elapsed = 0.0;

  static const _gap = 0.17;
  // Teal with a white ring, so the dots show on light and dark worlds.
  static final _dot = Paint()..color = const Color(0xD9007A7A);
  static final _ring = Paint()..color = const Color(0xF2FFFFFF);

  late final double _length = [
    for (var i = 1; i < points.length; i++) points[i].distanceTo(points[i - 1]),
  ].fold(0.0, (a, b) => a + b);

  @override
  void update(double dt) {
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    if (points.length < 2) return;
    final shown = drawIn <= 0 ? _length : _length * (_elapsed / drawIn);
    var travelled = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final segment = a.distanceTo(b);
      for (
        var d = travelled == 0 ? 0.0 : _gap - travelled % _gap;
        d <= segment;
        d += _gap
      ) {
        if (travelled + d > shown) return;
        // Clear of the character at the start and the finish at the end.
        final along = travelled + d;
        if (along < 0.35 || along > _length - 0.3) continue;
        final p = a + (b - a) * (d / segment);
        canvas
          ..drawCircle(Offset(p.x, p.y), 0.065, _ring)
          ..drawCircle(Offset(p.x, p.y), 0.045, _dot);
      }
      travelled += segment;
    }
  }
}
