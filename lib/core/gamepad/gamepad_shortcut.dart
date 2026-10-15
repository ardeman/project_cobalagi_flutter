import 'package:flutter/widgets.dart';

import 'package:cobalagi/core/gamepad/gamepad_scope.dart';
import 'package:cobalagi/core/gamepad/pad_badge.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';

/// Lets a controller [button] press this control directly, and pins that
/// button's badge to its corner while a controller is in use, so the child
/// sees which button does what. Pass the control's own callback as
/// [onPressed]; null (a disabled control) hides the badge.
class GamepadShortcut extends StatefulWidget {
  const GamepadShortcut({
    super.key,
    required this.button,
    required this.onPressed,
    required this.child,
    this.badgeOnLeft = false,
  });

  final PadButton button;

  /// Puts the badge on the top left corner, when the top right one already
  /// carries a badge of its own (the hint bulb's).
  final bool badgeOnLeft;
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
    _scope = scope;
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

  @override
  void dispose() {
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
    final show = scope.active && widget.onPressed != null;
    // Always a Stack, so the control keeps its state when the badge comes
    // and goes.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
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
