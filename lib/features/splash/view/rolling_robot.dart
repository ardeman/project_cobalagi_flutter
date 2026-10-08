import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cobalagi/core/character/robot_face.dart';

/// The splash screen's robot, rolling on the spot: its wheels turn, it
/// bounces on them, its head nods a beat behind, and it blinks. Road marks
/// slide past underneath so it reads as driving along. After [rollFor] it
/// parks (the splash only stays that long for an update notice), and it
/// holds still when the system asks for less motion.
///
/// The pictures come from `branding/robot.sh`: the head and body share the
/// game character's 512-pixel square, so the face and the wheel hubs are
/// placed in those pixels.
class RollingRobot extends StatefulWidget {
  const RollingRobot({
    super.key,
    this.size = 200,
    this.semanticLabel,
    this.rollFor = const Duration(seconds: 4),
  });

  final double size;

  /// How long it rolls before parking.
  final Duration rollFor;
  final String? semanticLabel;

  @override
  State<RollingRobot> createState() => _RollingRobotState();
}

class _RollingRobotState extends State<RollingRobot>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final t = elapsed.inMicroseconds / 1e6;
      _time.value = t;
      // Parks between bounces, with its wheels on the ground.
      if (elapsed >= widget.rollFor && sin(t * 7).abs() < 0.2) _ticker.stop();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive) {
      _ticker.stop();
      _time.value = 0;
    } else if (!still && !_ticker.isActive && _time.value == 0) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: widget.size,
          child: FittedBox(
            child: SizedBox.square(
              dimension: 512,
              child: ValueListenableBuilder<double>(
                valueListenable: _time,
                builder: (context, t, _) => _frame(t),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One frame of the robot at [t] seconds, in the pictures' 512 pixels.
  Widget _frame(double t) {
    // Bounces twice per wheel bump; the head follows a beat later and only
    // ever dips: lifting or tilting it would open a gap at the neck.
    final bounce = -(sin(t * 7).abs()) * 6;
    final nod = (1 - cos(t * 7 - 0.9)) * 1.5;
    return Stack(
      children: [
        CustomPaint(size: const Size.square(512), painter: _Road(t)),
        Transform.translate(
          offset: Offset(0, bounce),
          child: Stack(
            children: [
              Image.asset('assets/images/robot_body.png'),
              CustomPaint(
                size: const Size.square(512),
                painter: _Spokes(t * 7),
              ),
              Transform.translate(
                offset: Offset(0, nod),
                child: Stack(
                  children: [
                    Image.asset('assets/images/robot_head.png'),
                    CustomPaint(
                      size: const Size.square(512),
                      painter: _Face(t),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Face extends CustomPainter {
  const _Face(this.time);

  final double time;

  @override
  void paint(Canvas canvas, Size size) =>
      paintRobotFace(canvas, RobotFace.normal, time: time);

  @override
  bool shouldRepaint(_Face old) => old.time != time;
}

/// Spokes turning on both wheel hubs; [turn] is the wheels' angle.
class _Spokes extends CustomPainter {
  const _Spokes(this.turn);

  final double turn;

  static final _spoke = Paint()
    ..color = const Color(0xFF222244)
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round;

  /// Each hub's centre and radii in the picture: the near wheel is seen
  /// at a slant, so its hub is an upright oval.
  static const _hubs = [
    (center: Offset(216, 471), radii: Offset(8, 13.5)),
    (center: Offset(311.5, 464.5), radii: Offset(8.5, 8.5)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final hub in _hubs) {
      for (var i = 0; i < 3; i++) {
        final a = turn + i * 2 * pi / 3;
        canvas.drawLine(
          hub.center,
          hub.center + Offset(cos(a) * hub.radii.dx, sin(a) * hub.radii.dy),
          _spoke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Spokes old) => old.turn != turn;
}

/// Dashes under the wheels, sliding back as the robot drives forward.
class _Road extends CustomPainter {
  const _Road(this.time);

  final double time;

  static final _dash = Paint()
    ..color = const Color(0x33222244)
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    const y = 500.0, gap = 90.0, length = 34.0;
    // The wheels' rim moves about 15 pixels per radian.
    final shift = (time * 7 * 15) % gap;
    canvas
      ..save()
      ..clipRect(const Rect.fromLTRB(96, 480, 416, 512));
    for (var x = 96 - shift; x < 416 + gap; x += gap) {
      canvas.drawLine(Offset(x, y), Offset(x + length, y), _dash);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Road old) => old.time != time;
}
