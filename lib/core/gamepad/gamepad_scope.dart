import 'package:flutter/widgets.dart';

import 'package:cobalagi/core/gamepad/pad_input.dart';

/// A control a controller button presses directly ([GamepadShortcut]).
final class PadShortcutEntry {
  PadShortcutEntry(this.button, this.context, this.onPressed);

  final PadButton button;
  final BuildContext context;
  VoidCallback? onPressed;

  /// Only shortcuts on the top screen work: a dialog or sheet above blocks
  /// them, and so does a screen still sliding away.
  bool get available {
    if (onPressed == null || !context.mounted) return false;
    if (!TickerMode.valuesOf(context).enabled) return false;
    return ModalRoute.of(context)?.isCurrent ?? true;
  }
}

/// Something that takes the controller for a while, such as a guided tour:
/// shortcuts wait, and B calls [onBack].
final class PadCaptureEntry {
  PadCaptureEntry(this.onBack);

  VoidCallback onBack;
}

/// The controller's shortcuts and captures for the widgets below
/// [GamepadNavigator], and whether a controller is in use.
class GamepadScope extends InheritedWidget {
  const GamepadScope({
    super.key,
    required this.active,
    required this.shortcuts,
    required this.captures,
    required super.child,
  });

  /// True while the child plays with a controller: shortcuts show their
  /// button.
  final bool active;
  final List<PadShortcutEntry> shortcuts;
  final List<PadCaptureEntry> captures;

  /// Null outside a [GamepadNavigator], as in most widget tests.
  static GamepadScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GamepadScope>();

  @override
  bool updateShouldNotify(GamepadScope oldWidget) => active != oldWidget.active;
}
