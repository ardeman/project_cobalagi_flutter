import 'dart:math';

import 'package:cobalagi/core/character/robot_face.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Koba's head (`assets/images/robot_head.png`) with its face drawn in code,
/// its eyes turning to look at [lookAt], a point on the screen (global
/// coordinates); with none, it looks ahead.
///
/// The eyes glide there and it blinks now and then. Only its own layer
/// repaints: it never rebuilds while it watches.
class KobaHead extends StatefulWidget {
  const KobaHead({super.key, required this.size, this.lookAt});

  final double size;
  final Offset? lookAt;

  @override
  State<KobaHead> createState() => _KobaHeadState();
}

class _KobaHeadState extends State<KobaHead>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _look = _Look();
  Duration _lastTick = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // With reduced motion it neither blinks nor glides: the eyes jump to
    // where they look, after each layout.
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(KobaHead old) {
    super.didUpdateWidget(old);
    if (!_ticker.isActive) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _look.jumpTo(_aim());
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _look.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _look.glideTo(_aim(), dt: dt, time: elapsed.inMicroseconds / 1e6);
  }

  /// Where the pupils should sit, in the picture's 512 pixels: towards
  /// [KobaHead.lookAt], within the eyes.
  Offset _aim() {
    final at = widget.lookAt;
    final box = context.findRenderObject();
    if (at == null || box is! RenderBox || !box.hasSize || !box.attached) {
      return Offset.zero;
    }
    final toward = at - box.localToGlobal(box.size.center(Offset.zero));
    final distance = toward.distance;
    if (distance < 1) return Offset.zero;
    // Further off, the eyes turn further, up to the edge of the eye.
    final reach = min(1.0, distance / (widget.size * 3));
    return Offset(
      toward.dx / distance * 16 * reach,
      toward.dy / distance * 24 * reach,
    );
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/robot_head.png',
            errorBuilder: (_, _, _) => const SizedBox(),
          ),
          CustomPaint(painter: _FacePainter(_look)),
        ],
      ),
    ),
  );
}

/// Where the eyes look and the time for blinking, changed every frame
/// without a rebuild.
class _Look extends ChangeNotifier {
  var gaze = Offset.zero;
  var time = 0.0;

  void glideTo(Offset aim, {required double dt, required double time}) {
    this.time = time;
    // Eyes dart quickly, then settle.
    gaze = Offset.lerp(gaze, aim, min(1.0, dt * 12))!;
    notifyListeners();
  }

  void jumpTo(Offset aim) {
    if (gaze == aim) return;
    gaze = aim;
    notifyListeners();
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.look) : super(repaint: look);

  final _Look look;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 512);
    paintRobotFace(canvas, RobotFace.normal, time: look.time, gaze: look.gaze);
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.look != look;
}
