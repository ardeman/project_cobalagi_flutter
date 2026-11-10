import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../engine/examples/example.dart';

/// The picture of a thing: its colour, shape and size, with a navy outline
/// like Koba's, so two things can be told apart without words.
class ExamplePicture extends StatelessWidget {
  const ExamplePicture({super.key, required this.thing, required this.size});

  final ExampleThing thing;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: ExamplePicturePainter(thing),
  );
}

class ExamplePicturePainter extends CustomPainter {
  const ExamplePicturePainter(this.thing);

  final ExampleThing thing;

  @override
  void paint(Canvas canvas, Size size) {
    paintExampleThing(canvas, Offset.zero & size, thing);
  }

  @override
  bool shouldRepaint(ExamplePicturePainter oldDelegate) =>
      oldDelegate.thing != thing;
}

/// Draws [thing] inside [rect]. Shared by the sorting screen and the board.
void paintExampleThing(Canvas canvas, Rect rect, ExampleThing thing) {
  final colour = _colour(thing.colour);
  final fill = Paint()..color = colour;
  final edge = Paint()
    ..color = const Color(0xFF222244)
    ..style = PaintingStyle.stroke
    ..strokeWidth = rect.shortestSide * 0.06
    ..strokeJoin = StrokeJoin.round;
  final shine = Paint()..color = const Color(0x66FFFFFF);
  final scale = switch (thing.size) {
    ExampleSize.small => 0.62,
    ExampleSize.medium => 0.78,
    ExampleSize.big => 0.94,
  };
  final box = Rect.fromCenter(
    center: rect.center,
    width: rect.width * scale,
    height: rect.height * scale,
  );
  final path = switch (thing.shape) {
    ExampleShape.circle => Path()..addOval(box),
    ExampleShape.square =>
      Path()..addRRect(
        RRect.fromRectAndRadius(box, Radius.circular(box.width * 0.18)),
      ),
    ExampleShape.triangle =>
      Path()
        ..moveTo(box.center.dx, box.top)
        ..lineTo(box.right, box.bottom)
        ..lineTo(box.left, box.bottom)
        ..close(),
    ExampleShape.star => _star(box),
  };
  canvas
    ..drawPath(path, fill)
    ..drawPath(path, edge);
  canvas.drawCircle(
    box.center + Offset(-box.width * 0.16, -box.height * 0.16),
    box.shortestSide * 0.12,
    shine,
  );
}

Color _colour(ExampleColour colour) => switch (colour) {
  ExampleColour.green => const Color(0xFF43A047),
  ExampleColour.red => const Color(0xFFE53935),
  ExampleColour.blue => const Color(0xFF1E88E5),
  ExampleColour.yellow => const Color(0xFFF9A825),
};

Path _star(Rect box) {
  final path = Path();
  final centre = box.center;
  final outer = box.width / 2;
  final inner = outer * 0.42;
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? outer : inner;
    final angle = -pi / 2 + i * pi / 5;
    final point = centre + Offset(cos(angle), sin(angle)) * radius;
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  return path..close();
}
