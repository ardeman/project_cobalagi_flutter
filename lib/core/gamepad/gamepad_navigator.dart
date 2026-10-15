import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepads/gamepads.dart';

import 'package:cobalagi/core/gamepad/gamepad_cubit.dart';
import 'package:cobalagi/core/gamepad/gamepad_scope.dart';
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
          GamepadButton.start => input.button(PadButton.menu, down: down),
          GamepadButton.back => input.button(PadButton.view, down: down),
          null => switch (event.axis) {
            GamepadAxis.leftStickX => input.stick(x: event.value),
            GamepadAxis.leftStickY => input.stick(y: event.value),
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
    with SingleTickerProviderStateMixin {
  final _shortcuts = <PadShortcutEntry>[];
  final _captures = <PadCaptureEntry>[];
  final _ring = ValueNotifier<Rect?>(null);
  late final Ticker _ticker;
  var _active = false;
  StreamSubscription<PadCommand>? _subscription;

  /// How long the ring follows its control after something moved it: long
  /// enough for a scroll into view or a page transition to finish.
  static const _followFor = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_follow);
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
    _ring.dispose();
    super.dispose();
  }

  void _handle(PadCommand command) {
    context.read<GamepadCubit>().used();
    _track();
    switch (command) {
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
        if (_captures.isNotEmpty) {
          if (button == PadButton.b) _captures.last.onBack();
          return;
        }
        final shortcut = _shortcuts.reversed
            .where((s) => s.button == button && s.available)
            .firstOrNull;
        if (shortcut != null) {
          shortcut.onPressed!();
        } else if (button == PadButton.b) {
          final focused = FocusManager.instance.primaryFocus?.context;
          if (focused != null) Navigator.maybeOf(focused)?.maybePop();
        }
    }
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
    final node = FocusManager.instance.primaryFocus;
    final box = node is FocusScopeNode
        ? null
        : node?.context?.findRenderObject();
    final rect = box is RenderBox && box.attached && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    if (rect != _ring.value) _ring.value = rect;
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
        onPointerDown: (_) => context.read<GamepadCubit>().touched(),
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
