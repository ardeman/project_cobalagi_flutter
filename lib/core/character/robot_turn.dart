import 'dart:math';
import 'dart:ui';

import 'package:cobalagi/core/character/robot_face.dart';

/// Frames in `assets/images/robot_turn.webp` (made by
/// `tool/robot/render_turn.py`): the 3D robot turning on the spot, 256
/// pixels each, six to a row, each turned a step further from facing the
/// child towards its right, the wheels rolling opposite ways.
const robotTurnFrameCount = 24;

/// The turning frame to show for a facing [angle] on the screen (clockwise
/// from up the board), or null when it faces along the board: the drawn
/// pictures show then. The puzzle's world and the story share it, so Koba
/// turns the same way in both.
int? robotTurnFrame(double angle) {
  final quarters = angle / (pi / 2);
  if ((quarters - quarters.roundToDouble()).abs() < 0.04) return null;
  // The drawn pictures as turns of the 3D robot, in degrees, clockwise
  // on the screen from facing up: its back, the three-quarter picture
  // (facing right), its front, the three-quarter picture mirrored, its
  // back again. In between, it turns evenly.
  const pictures = [180.0, 310.0, 360.0, 410.0, 540.0];
  final at = quarters % 4;
  final i = at.floor();
  final degrees = pictures[i] + (pictures[i + 1] - pictures[i]) * (at - i);
  return (degrees * robotTurnFrameCount / 360).round() % robotTurnFrameCount;
}

final _smooth = Paint()..filterQuality = FilterQuality.medium;

/// Turning [frame] of [frames], in the 512 pixels of Koba's drawn pictures,
/// with [face] on its screen while the screen shows.
void paintRobotTurning(
  Canvas canvas,
  Image frames,
  int frame,
  RobotFace face, {
  required double time,
}) {
  canvas.drawImageRect(
    frames,
    Rect.fromLTWH(frame % 6 * 256, frame ~/ 6 * 256, 256, 256),
    const Rect.fromLTWH(0, 0, 512, 512),
    _smooth,
  );
  // How far the frame is turned, and where the middle of its screen shows
  // then, in the 512 pixels of the drawn pictures: measured on the frames,
  // as the curved screen's front (render_turn.py's numbers) swings
  // further round than the part that shows.
  final turned = frame * 2 * pi / robotTurnFrameCount;
  if (cos(turned) < 0.2) return;
  paintRobotFace(
    canvas,
    face,
    time: time,
    gaze: Offset(-sin(turned) * 14, 0),
    at: Offset(256 - 75 * sin(turned), 194),
    squash: cos(turned),
  );
}
