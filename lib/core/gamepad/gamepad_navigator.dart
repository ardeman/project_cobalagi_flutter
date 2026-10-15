import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepads/gamepads.dart';

import 'package:cobalagi/core/gamepad/gamepad_cubit.dart';
import 'package:cobalagi/core/gamepad/gamepad_scope.dart';
import 'package:cobalagi/core/gamepad/pad_badge.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';

/// Commands from every connected controller (Steam Deck, Xbox, PlayStation
/// and others), with buttons named the same on every platform.
Stream<PadCommand> controllerCommands() {
  final input = PadInput();
  return Gamepads.normalizedEvents
      .map((event) {
        final down = event.value > 0.5;
        return switch (event.button) {
          GamepadButton.dpadUp => input.dpad(PadDirection.up, down: down),
          GamepadButton.dpadDown => input.dpad(PadDirection.down, down: down),
          GamepadButton.dpadLeft => input.dpad(PadDirection.left, down: down),
          GamepadButton.dpadRight => input.dpad(PadDirection.right, down: down),
          GamepadButton.a => input.button(PadButton.a, down: down),
          GamepadButton.b => input.button(PadButton.b, down: down),
          GamepadButton.x => input.button(PadButton.x, down: down),
          GamepadButton.y => input.button(PadButton.y, down: down),
          GamepadButton.leftBumper => input.button(
            PadButton.leftBumper,
            down: down,
          ),
          GamepadButton.rightBumper => input.button(
            PadButton.rightBumper,
            down: down,
          ),
          GamepadButton.rightStick => input.button(
            PadButton.rightStick,
            down: down,
          ),
          GamepadButton.leftStick => input.button(
            PadButton.leftStick,
            down: down,
          ),
          GamepadButton.rightTrigger => input.button(
            PadButton.rightTrigger,
            down: down,
          ),
          GamepadButton.start => input.button(PadButton.menu, down: down),
          GamepadButton.back => input.button(PadButton.view, down: down),
          null => switch (event.axis) {
            GamepadAxis.leftStickX => input.stick(x: event.value),
            GamepadAxis.leftStickY => input.stick(y: event.value),
            GamepadAxis.rightStickY => input.scrollStick(event.value),
            GamepadAxis.rightTrigger => input.trigger(
              PadButton.rightTrigger,
              event.value,
            ),
            _ => null,
          },
          _ => null,
        };
      })
      .where((command) => command != null)
      .cast<PadCommand>();
}

/// Lets children play with a controller, like a TV menu: the d-pad or left
/// stick moves a glowing highlight from control to control, A presses it, B
/// goes back, and other buttons press the controls that show their badge
/// ([GamepadShortcut]). Touching the screen hides the highlight and badges
/// until the controller is used again.
class GamepadNavigator extends StatefulWidget {
  const GamepadNavigator({super.key, this.commands, required this.child});

  /// The controllers' input; null listens to none (tests, and platforms the
  /// app doesn't wire up).
  final Stream<PadCommand>? commands;
  final Widget child;

  @override
  State<GamepadNavigator> createState() => _GamepadNavigatorState();
}

class _GamepadNavigatorState extends State<GamepadNavigator>
    with TickerProviderStateMixin {
  final _shortcuts = <PadShortcutEntry>[];
  final _captures = PadCaptures();
  final _ring = ValueNotifier<Rect?>(null);

  /// Where the R2 badge goes: on the highlighted block, which R2 carries.
  final _grabAt = ValueNotifier<Rect?>(null);
  late final Ticker _ticker;

  /// Scrolls while the right stick leans ([PadScroll]).
  late final Ticker _scroller;
  var _scrollSpeed = 0.0;
  ScrollableState? _scrolling;
  Duration _scrolledAt = Duration.zero;

  /// Pixels a second with the stick leaned all the way.
  static const _scrollFull = 1400.0;

  /// The virtual finger R2 and the left stick drag with: it feeds the same
  /// touch drag a finger does, so blocks float, show where they land and
  /// drop the same way.
  static const _fingerDevice = 0x4C41;
  static const _fingerPointer = 0x4C410001;

  /// Pixels a second with the stick leaned all the way.
  static const _fingerSpeed = 900.0;
  late final Ticker _fingerTicker;
  Duration _fingerMovedAt = Duration.zero;
  final _finger = ValueNotifier<Offset?>(null);
  var _aim = Offset.zero;

  /// Where the highlighted control was when R2 went down; null when R2 is
  /// up.
  Rect? _grabbedFrom;
  var _active = false;
  StreamSubscription<PadCommand>? _subscription;

  /// How long the ring follows its control after something moved it: long
  /// enough for a scroll into view or a page transition to finish.
  static const _followFor = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_follow);
    _scroller = createTicker(_scroll);
    _fingerTicker = createTicker(_moveFinger);
    FocusManager.instance.addListener(_track);
    _listen();
  }

  @override
  void didUpdateWidget(GamepadNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commands != widget.commands) _listen();
  }

  void _listen() {
    _subscription?.cancel();
    // A controller error must never stop play.
    _subscription = widget.commands?.listen(_handle, onError: (_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    FocusManager.instance.removeListener(_track);
    _ticker.dispose();
    _scroller.dispose();
    _fingerTicker.dispose();
    _finger.dispose();
    _captures.dispose();
    _ring.dispose();
    _grabAt.dispose();
    super.dispose();
  }

  void _handle(PadCommand command) {
    context.read<GamepadCubit>().used();
    _track();
    switch (command) {
      case PadScroll(:final speed):
        _scrollSpeed = speed;
        if (speed == 0) {
          _scroller.stop();
        } else if (!_scroller.isActive) {
          _scrolledAt = Duration.zero;
          _scrolling = _scrollable();
          if (_scrolling != null) _scroller.start();
        }
      case PadAim(:final x, :final y):
        _aim = Offset(x, y);
        if (_finger.value == null) {
          _startFinger();
        } else if (_aim != Offset.zero && !_fingerTicker.isActive) {
          _fingerMovedAt = Duration.zero;
          _fingerTicker.start();
        }
      case PadRelease(button: PadButton.rightTrigger)
          when _finger.value != null:
        _grabbedFrom = null;
        _endFinger(cancel: false);
      case PadRelease(:final button):
        if (button == PadButton.rightTrigger) _grabbedFrom = null;
        _captures.lastOrNull?.onRelease?.call(button);
      case PadPress(button: PadButton.b) when _finger.value != null:
        _endFinger(cancel: true);
      case PadPress() when _finger.value != null:
        break;
      case PadPress(button: PadButton.rightTrigger)
          when _captures.lastOrNull == null:
        _grabbedFrom = _focusedRect();
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused != null) {
          Actions.maybeInvoke(focused, const PadGrabIntent());
        }
      case PadMove(:final direction) when _captures.lastOrNull?.onMove != null:
        _captures.lastOrNull!.onMove!(direction);
      case PadPress(button: PadButton.a)
          when _captures.lastOrNull?.onConfirm != null:
        _captures.lastOrNull!.onConfirm!();
      case PadMove(:final direction):
        FocusManager.instance.primaryFocus?.focusInDirection(
          switch (direction) {
            PadDirection.up => TraversalDirection.up,
            PadDirection.down => TraversalDirection.down,
            PadDirection.left => TraversalDirection.left,
            PadDirection.right => TraversalDirection.right,
          },
        );
      case PadPress(button: PadButton.a):
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused != null) {
          Actions.maybeInvoke(focused, const ActivateIntent());
        }
      case PadPress(:final button):
        final capture = _captures.lastOrNull;
        if (capture != null && button == PadButton.b) {
          capture.onBack();
          return;
        }
        // While something has the controller, only its own shortcuts work
        // (the tour bubble's speaker).
        final shortcut = _shortcuts.reversed
            .where(
              (s) => s.button == button && s.available && _captures.allows(s),
            )
            .firstOrNull;
        if (shortcut != null) {
          shortcut.onPressed!();
        } else if (button == PadButton.b && capture == null) {
          final focused = FocusManager.instance.primaryFocus?.context;
          if (focused != null) Navigator.maybeOf(focused)?.maybePop();
        }
    }
  }

  /// The stick leaned with R2 held: the carry hands over to the finger,
  /// which presses where the block is and starts dragging it.
  void _startFinger({bool retried = false}) {
    final from = _grabbedFrom;
    if (from == null || _aim == Offset.zero) return;
    final capture = _captures.lastOrNull;
    final freeDrag = capture?.onFreeDrag;
    if (freeDrag == null) {
      // The carry starts on the next frame: try once more then.
      if (!retried) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _startFinger(retried: true),
        );
      }
      return;
    }
    final moved = freeDrag();
    void press(Offset at) {
      if (_grabbedFrom == null || _finger.value != null) return;
      _finger.value = at;
      _ring.value = null;
      GestureBinding.instance.handlePointerEvent(
        PointerDownEvent(
          pointer: _fingerPointer,
          device: _fingerDevice,
          position: at,
        ),
      );
      _fingerMovedAt = Duration.zero;
      _fingerTicker.start();
    }

    if (!moved) {
      press(from.center);
    } else {
      // The block lands first; press it once it is laid out there.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => press((_focusedRect() ?? from).center),
      );
    }
  }

  void _moveFinger(Duration elapsed) {
    final at = _finger.value;
    if (at == null || _aim == Offset.zero) {
      _fingerTicker.stop();
      return;
    }
    final seconds = (elapsed - _fingerMovedAt).inMicroseconds / 1e6;
    _fingerMovedAt = elapsed;
    final size = context.size ?? Size.zero;
    final to = at + _aim * (_fingerSpeed * seconds);
    final clamped = Offset(
      to.dx.clamp(0, size.width),
      to.dy.clamp(0, size.height),
    );
    if (clamped == at) return;
    _finger.value = clamped;
    GestureBinding.instance.handlePointerEvent(
      PointerMoveEvent(
        pointer: _fingerPointer,
        device: _fingerDevice,
        position: clamped,
        delta: clamped - at,
      ),
    );
  }

  /// Lets go (drops where the block is) or, with [cancel], drags nothing.
  void _endFinger({required bool cancel}) {
    final at = _finger.value;
    if (at == null) return;
    _fingerTicker.stop();
    _finger.value = null;
    _aim = Offset.zero;
    GestureBinding.instance.handlePointerEvent(
      cancel
          ? PointerCancelEvent(
              pointer: _fingerPointer,
              device: _fingerDevice,
              position: at,
            )
          : PointerUpEvent(
              pointer: _fingerPointer,
              device: _fingerDevice,
              position: at,
            ),
    );
    _track();
  }

  Rect? _focusedRect() {
    final node = FocusManager.instance.primaryFocus;
    final box = node is FocusScopeNode
        ? null
        : node?.context?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
  }

  /// Scrolls the list or page the highlight is in, else the screen's.
  void _scroll(Duration elapsed) {
    final seconds = (elapsed - _scrolledAt).inMicroseconds / 1e6;
    _scrolledAt = elapsed;
    final scrolling = _scrolling;
    if (scrolling == null || !scrolling.mounted) {
      _scroller.stop();
      return;
    }
    final position = scrolling.position;
    final to = (position.pixels + _scrollSpeed * _scrollFull * seconds).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (to != position.pixels) position.jumpTo(to);
  }

  ScrollableState? _scrollable() {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null) {
      final around = Scrollable.maybeOf(focused, axis: Axis.vertical);
      if (around != null) return around;
    }
    // Nothing focused in a list: the first one on this screen that can
    // scroll.
    ScrollableState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element case StatefulElement(:final ScrollableState state)
          when state.position.axis == Axis.vertical &&
              state.position.maxScrollExtent > 0) {
        found = state;
        return;
      }
      element.visitChildElements(visit);
    }

    final screen = focused == null
        ? null
        : ModalRoute.of(focused)?.subtreeContext;
    (screen ?? context).visitChildElements(visit);
    return found;
  }

  void _onActive(bool active) {
    FocusManager.instance.highlightStrategy = active
        ? FocusHighlightStrategy.alwaysTraditional
        : FocusHighlightStrategy.automatic;
    _active = active;
    if (active) {
      _track();
    } else {
      _ticker.stop();
      _ring.value = null;
      _grabAt.value = null;
    }
  }

  /// Follows the focused control for a moment: focus changes, scrolling and
  /// page transitions move it. Never every frame, so the screen can rest.
  void _track() {
    if (!_active) return;
    _ticker
      ..stop()
      ..start();
  }

  void _follow(Duration elapsed) {
    _placeRing();
    if (elapsed > _followFor) _ticker.stop();
  }

  void _placeRing() {
    // While the finger drags, the hand shows where it is instead.
    if (_finger.value != null) {
      _ring.value = null;
      _grabAt.value = null;
      return;
    }
    final node = FocusManager.instance.primaryFocus;
    final box = node is FocusScopeNode
        ? null
        : node?.context?.findRenderObject();
    final rect = box is RenderBox && box.attached && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    if (rect != _ring.value) _ring.value = rect;
    final context = node?.context;
    final grab =
        rect != null &&
        context != null &&
        context.mounted &&
        Actions.maybeFind<PadGrabIntent>(context) != null;
    final grabAt = grab ? rect : null;
    if (grabAt != _grabAt.value) _grabAt.value = grabAt;
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<GamepadCubit, bool>(
    listener: (_, active) => _onActive(active),
    builder: (context, active) => GamepadScope(
      active: active,
      shortcuts: _shortcuts,
      captures: _captures,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          // The virtual finger is the controller's own.
          if (event.device != _fingerDevice) {
            context.read<GamepadCubit>().touched();
          }
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (_) {
            _track();
            return false;
          },
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _FocusRing(_ring)),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<Rect?>(
                    valueListenable: _grabAt,
                    builder: (context, at, _) => Stack(
                      children: [
                        if (at != null)
                          Positioned(
                            left: at.right - 18,
                            top: at.top - 18,
                            child: const PadBadge(
                              button: PadButton.rightTrigger,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // The virtual finger, while the stick drags.
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<Offset?>(
                    valueListenable: _finger,
                    builder: (context, at, _) => Stack(
                      children: [
                        if (at != null)
                          Positioned(
                            // The fingertip sits on the point.
                            left: at.dx - 15,
                            top: at.dy - 4,
                            child: const Icon(
                              Icons.touch_app_rounded,
                              size: 40,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 6, color: Colors.black87),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A thick glowing ring around the focused control, easy to spot from the
/// sofa.
class _FocusRing extends CustomPainter {
  _FocusRing(this.rect) : super(repaint: rect);

  final ValueNotifier<Rect?> rect;

  @override
  void paint(Canvas canvas, Size size) {
    final r = rect.value;
    if (r == null) return;
    final ring = RRect.fromRectAndRadius(
      r.inflate(6),
      const Radius.circular(18),
    );
    canvas
      ..drawRRect(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = const Color(0xFF2EC4F1).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawRRect(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xFF2EC4F1),
      )
      ..drawRRect(
        ring.deflate(3.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
  }

  @override
  bool shouldRepaint(_FocusRing oldDelegate) => oldDelegate.rect != rect;
}
