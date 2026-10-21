import 'dart:async';
import 'dart:math';

import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/core/gamepad/gamepad_scope.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Koba's head (`assets/images/robot_head.png`) with its face drawn in code,
/// its eyes turning to look at [lookAt], a point on the screen (global
/// coordinates); with none, it looks ahead.
///
/// The eyes glide there and it blinks now and then. Only its own layer
/// repaints: it never rebuilds while it watches.
class KobaHead extends StatefulWidget {
  const KobaHead({super.key, required this.size, this.lookAt}) : follow = false;

  /// Koba watching the child: its eyes follow a touch (or the mouse) anywhere
  /// on the screen for a moment and, while a controller is in use, the
  /// highlighted control; otherwise it looks ahead.
  const KobaHead.follow({super.key, required this.size})
    : lookAt = null,
      follow = true;

  final double size;
  final Offset? lookAt;
  final bool follow;

  @override
  State<KobaHead> createState() => _KobaHeadState();
}

class _KobaHeadState extends State<KobaHead>
    with SingleTickerProviderStateMixin {
  /// Runs only while the eyes glide, so a Koba at rest costs nothing; made
  /// on the first glide, never in [dispose] (a ticker looks up [TickerMode]).
  Ticker? _ticker;
  final _look = _Look();
  Duration _lastTick = Duration.zero;
  Timer? _blinks;
  Timer? _blinkEnds;
  var _still = false;

  /// Where the child last touched, for a moment ([KobaHead.follow]).
  Offset? _finger;
  Timer? _fingerGone;
  var _padActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.follow) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_pointed);
      FocusManager.instance.addListener(_looked);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // With reduced motion it neither blinks nor glides: the eyes jump to
    // where they look.
    _still = MediaQuery.disableAnimationsOf(context);
    _blinks?.cancel();
    _blinks = _still
        ? null
        : Timer.periodic(const Duration(milliseconds: 3600), (_) => _blink());
    if (widget.follow) {
      _padActive = GamepadScope.maybeOf(context)?.active ?? false;
    }
    _looked();
  }

  @override
  void didUpdateWidget(KobaHead old) {
    super.didUpdateWidget(old);
    _looked();
  }

  @override
  void dispose() {
    if (widget.follow) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointed);
      FocusManager.instance.removeListener(_looked);
    }
    _fingerGone?.cancel();
    _blinks?.cancel();
    _blinkEnds?.cancel();
    _ticker?.dispose();
    _look.dispose();
    super.dispose();
  }

  void _blink() {
    _look.setBlink(true);
    _blinkEnds?.cancel();
    _blinkEnds = Timer(
      const Duration(milliseconds: 150),
      () => _look.setBlink(false),
    );
  }

  void _pointed(PointerEvent event) {
    if (event is! PointerDownEvent &&
        event is! PointerMoveEvent &&
        event is! PointerHoverEvent) {
      return;
    }
    _finger = event.position;
    _fingerGone?.cancel();
    _fingerGone = Timer(const Duration(milliseconds: 1500), () {
      _finger = null;
      _looked();
    });
    _looked();
  }

  /// Something it looks at may have moved: after the next layout, the eyes
  /// glide there (or jump, with reduced motion).
  void _looked() {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final aim = _aim();
      if (_still) {
        _look.jumpTo(aim);
      } else if (aim != _look.gaze && !(_ticker?.isActive ?? false)) {
        _lastTick = Duration.zero;
        (_ticker ??= createTicker(_tick)).start();
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// What the eyes look at: [KobaHead.lookAt], or when following, a recent
  /// touch, else the controller's highlighted control.
  Offset? _target() {
    if (!widget.follow) return widget.lookAt;
    if (_finger != null) return _finger;
    if (!_padActive) return null;
    final box = FocusManager.instance.primaryFocus?.context?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (_look.glideTo(_aim(), dt: dt)) _ticker?.stop();
  }

  /// Where the pupils should sit, in the picture's 512 pixels: towards
  /// what it looks at, within the eyes.
  Offset _aim() {
    final at = _target();
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

/// Where the eyes look and whether they blink, changed without a rebuild.
class _Look extends ChangeNotifier {
  var gaze = Offset.zero;

  /// The face's clock: [paintRobotFace] blinks in the last moment of each
  /// 3.6 seconds, so a blink is a time in that moment.
  var time = 0.0;

  /// Moves the eyes part of the way to [aim]; true once they are there.
  bool glideTo(Offset aim, {required double dt}) {
    // Eyes dart quickly, then settle.
    final next = Offset.lerp(gaze, aim, min(1.0, dt * 12))!;
    final there = (next - aim).distance < 0.2;
    gaze = there ? aim : next;
    notifyListeners();
    return there;
  }

  void jumpTo(Offset aim) {
    if (gaze == aim) return;
    gaze = aim;
    notifyListeners();
  }

  void setBlink(bool blinking) {
    time = blinking ? 3.5 : 0;
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
