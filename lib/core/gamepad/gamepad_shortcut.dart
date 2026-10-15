import 'package:flutter/widgets.dart';

import 'package:cobalagi/core/gamepad/gamepad_scope.dart';
import 'package:cobalagi/core/gamepad/pad_badge.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';

/// Lets a controller [button] press this control directly, and pins that
/// button's badge to its corner while a controller is in use, so the child
/// sees which button does what. Pass the control's own callback as
/// [onPressed]; null (a disabled control) hides the badge. The highlight
/// skips the control, since its button already presses it.
class GamepadShortcut extends StatefulWidget {
  const GamepadShortcut({
    super.key,
    required this.button,
    required this.onPressed,
    required this.child,
    this.badgeOnLeft = false,
    this.keepFocusable = false,
  });

  final PadButton button;

  /// Puts the badge on the top left corner, when the top right one already
  /// carries a badge of its own (the hint bulb's).
  final bool badgeOnLeft;

  /// Lets the highlight still reach the control, when the button is an
  /// extra action on something the child also picks (L1 on a block).
  final bool keepFocusable;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<GamepadShortcut> createState() => _GamepadShortcutState();
}

class _GamepadShortcutState extends State<GamepadShortcut> {
  GamepadScope? _scope;
  PadShortcutEntry? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = GamepadScope.maybeOf(context);
    if (identical(scope?.shortcuts, _scope?.shortcuts)) {
      _scope = scope;
      return;
    }
    _unregister();
    _scope?.captures.removeListener(_rebuild);
    _scope = scope;
    scope?.captures.addListener(_rebuild);
    if (scope != null) {
      _entry = PadShortcutEntry(widget.button, context, widget.onPressed);
      scope.shortcuts.add(_entry!);
    }
  }

  @override
  void didUpdateWidget(GamepadShortcut oldWidget) {
    super.didUpdateWidget(oldWidget);
    final entry = _entry;
    if (entry == null) return;
    if (oldWidget.button != widget.button) {
      _unregister();
      _entry = PadShortcutEntry(widget.button, context, widget.onPressed);
      _scope!.shortcuts.add(_entry!);
    } else {
      entry.onPressed = widget.onPressed;
    }
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _scope?.captures.removeListener(_rebuild);
    _unregister();
    super.dispose();
  }

  void _unregister() {
    if (_entry != null) _scope?.shortcuts.remove(_entry);
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    if (scope == null) return widget.child;
    // A paused shortcut (the screen's, under a tour) hides its badge.
    final show =
        scope.active &&
        widget.onPressed != null &&
        (_entry == null || scope.captures.allows(_entry!));
    // Always a Stack, so the control keeps its state when the badge comes
    // and goes.
    // Passthrough: the control is laid out exactly as without the badge (a
    // button in an Expanded stays stretched).
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        if (widget.keepFocusable)
          widget.child
        else
          ExcludeFocus(child: widget.child),
        if (show)
          Positioned(
            top: -8,
            left: widget.badgeOnLeft ? -8 : null,
            right: widget.badgeOnLeft ? null : -8,
            child: IgnorePointer(child: PadBadge(button: widget.button)),
          ),
      ],
    );
  }
}
