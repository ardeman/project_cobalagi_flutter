import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show IconData;

/// One step of a hint, drawn on the map like the block that makes it: its
/// colour and picture. Holds no game logic; the play view decides what each
/// step is.
final class HintMark {
  const HintMark({
    required this.at,
    required this.icon,
    required this.color,
    this.angle = 0,
    this.label,
    this.labelFont,
    this.faded = false,
    this.big = false,
  });

  /// Where the mark sits, in tiles (0.5 is a tile's centre).
  final Vector2 at;
  final IconData icon;
  final Color color;

  /// Rotates the picture, so an arrow points the way the character walks.
  final double angle;

  /// A small number on the mark, such as how many steps a Step Box holds.
  final String? label;

  /// The app's text font for [label]; the world has no theme of its own.
  final String? labelFont;

  /// Drawn see-through: a step the pattern hint says comes again.
  final bool faded;

  /// Drawn larger (1.6 times): the loop block that the pattern hint
  /// suggests.
  final bool big;
}

/// A [HintMark] drawn as a small block: a rounded square in the block's
/// colour with its white picture.
class HintMarkComponent extends PositionComponent {
  HintMarkComponent(this.mark)
    : super(position: mark.at, size: Vector2.all(_size), anchor: Anchor.center);

  final HintMark mark;

  static const _size = 0.46;

  late final _fill = Paint()..color = mark.color;
  static final _edge = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;
  static final _shadow = Paint()..color = const Color(0x40000000);

  late final TextPainter _icon = _glyph(
    String.fromCharCode(mark.icon.codePoint),
    TextStyle(
      fontSize: 1,
      fontFamily: mark.icon.fontFamily,
      package: mark.icon.fontPackage,
      color: const Color(0xFFFFFFFF),
    ),
  );

  late final TextPainter? _label = mark.label == null
      ? null
      : _glyph(
          mark.label!,
          TextStyle(
            fontSize: 1,
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
    if (mark.faded) {
      canvas.saveLayer(null, Paint()..color = const Color(0x5CFFFFFF));
    }
    _draw(canvas);
    if (mark.faded) canvas.restore();
  }

  void _draw(Canvas canvas) {
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, _size, _size),
      const Radius.circular(0.12),
    );
    canvas
      ..drawRRect(box.shift(const Offset(0.02, 0.03)), _shadow)
      ..drawRRect(box, _fill)
      ..drawRRect(box, _edge);
    // The picture, turned with the mark's angle around its centre.
    const glyph = 0.32;
    canvas
      ..save()
      ..translate(_size / 2, _size / 2)
      ..rotate(mark.angle)
      ..scale(glyph / _icon.height)
      ..translate(-_icon.width / 2, -_icon.height / 2);
    _icon.paint(canvas, Offset.zero);
    canvas.restore();
    if (_label case final label?) {
      // A white bubble on the corner holding the number, outlined in the
      // block's colour.
      const r = 0.17;
      const centre = Offset(_size - 0.02, 0.02);
      canvas
        ..drawCircle(centre, r, Paint()..color = const Color(0xFFFFFFFF))
        ..drawCircle(
          centre,
          r,
          Paint()
            ..color = mark.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.04,
        )
        ..save()
        ..translate(centre.dx, centre.dy)
        ..scale(0.26 / label.height)
        ..translate(-label.width / 2, -label.height / 2);
      label.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }
}
