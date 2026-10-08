import 'dart:math';
import 'dart:ui';

/// The faces the robot shows on its screen.
enum RobotFace { normal, dizzy, cheer }

final _screen = Paint()..color = const Color(0xFF454553);
final _white = Paint()..color = const Color(0xFFFFFFFF);
final _ink = Paint()..color = const Color(0xFF222244);
final _cheek = Paint()..color = const Color(0xFFFFE08A);
final _gold = Paint()..color = const Color(0xFFFFC83D);
final _line = Paint()
  ..color = const Color(0xFFFFFFFF)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 9
  ..strokeCap = StrokeCap.round;

/// Draws the robot's [face] over the screen of its picture
/// (`assets/images/robot.png`, and the splash's `robot_head.png`), on a
/// [canvas] measured in the picture's 512 pixels. [time] (seconds) drives
/// the blink and the dizzy spin; [gaze] moves the pupils, in those pixels.
/// With [front] it sits on the screen of `assets/images/robot_front.png`
/// (the robot facing the child), straight; that picture's screen is already
/// clear (`tool/robot/front.html` erases the face and prints where the
/// screen is).
/// The game and the splash screen share it, so the robot looks the same.
void paintRobotFace(
  Canvas canvas,
  RobotFace face, {
  required double time,
  Offset gaze = Offset.zero,
  bool front = false,
}) {
  // Blinks for a moment every few seconds.
  final blinking = (time % 3.6) > 3.45;
  canvas.save();
  // The screen tilts a little, like the picture's.
  if (front) {
    canvas.translate(265, 219);
  } else {
    canvas
      ..translate(292, 218)
      ..rotate(-0.17);
  }
  // Paints over the picture's own face.
  if (!front) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-96, -72, 96, 72),
        const Radius.circular(36),
      ),
      _screen,
    );
  }
  switch (face) {
    case RobotFace.normal:
      for (final x in [-48.0, 48.0]) {
        if (blinking) {
          canvas.drawLine(Offset(x - 22, -6), Offset(x + 22, -6), _line);
        } else {
          canvas
            ..drawOval(
              Rect.fromCenter(center: Offset(x, -8), width: 52, height: 78),
              _white,
            )
            ..drawCircle(Offset(x, -8) + gaze, 15, _ink)
            ..drawCircle(Offset(x + 5, -15) + gaze, 5, _white);
        }
      }
      canvas
        ..drawCircle(const Offset(-70, 38), 8, _cheek)
        ..drawCircle(const Offset(70, 38), 8, _cheek);
      canvas.drawArc(
        const Rect.fromLTWH(-16, 22, 32, 22),
        0.2,
        2.74,
        false,
        _line,
      );
    case RobotFace.dizzy:
      for (final x in [-48.0, 48.0]) {
        final spiral = Path();
        for (var t = 0.0; t < 12; t += 0.2) {
          final r = 3 + t * 2.2;
          final p = Offset(
            x + cos(t + time * 9) * r,
            -6 + sin(t + time * 9) * r,
          );
          t == 0 ? spiral.moveTo(p.dx, p.dy) : spiral.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(spiral, _line);
      }
      // A wobbly zigzag mouth.
      final mouth = Path()..moveTo(-24, 40);
      for (var i = 1; i <= 8; i++) {
        mouth.lineTo(-24 + i * 6.0, i.isEven ? 40 : 34);
      }
      canvas.drawPath(mouth, _line);
    case RobotFace.cheer:
      for (final x in [-48.0, 48.0]) {
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? 30.0 : 13.0;
          final a = -pi / 2 + i * pi / 5;
          final p = Offset(x + cos(a) * r, -8 + sin(a) * r);
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(star..close(), _gold);
      }
      canvas.drawPath(
        Path()
          ..moveTo(-28, 26)
          ..quadraticBezierTo(0, 70, 28, 26)
          ..close(),
        _white,
      );
  }
  canvas.restore();
}
