import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:cobalagi/core/gamepad/pad_input.dart';

/// A control a controller button presses directly ([GamepadShortcut]).
final class PadShortcutEntry {
  PadShortcutEntry(this.button, this.context, this.onPressed);

  final PadButton button;
  final BuildContext context;
  VoidCallback? onPressed;

  /// Whether this control sits inside [outer] (a capture's widget).
  bool isInside(BuildContext outer) {
    if (!context.mounted || !outer.mounted) return false;
    var inside = false;
    context.visitAncestorElements((element) {
      inside = identical(element, outer);
      return !inside;
    });
    return inside;
  }

  /// Only shortcuts on the top screen work: a dialog or sheet above blocks
  /// them, and so does a screen still sliding away.
  bool get available {
    if (onPressed == null || !context.mounted) return false;
    if (!TickerMode.valuesOf(context).enabled) return false;
    return ModalRoute.of(context)?.isCurrent ?? true;
  }
}

/// Something that takes the controller for a while, such as a guided tour
/// or a block being carried: only shortcuts inside [context] work, and B
/// calls [onBack].
final class PadCaptureEntry {
  PadCaptureEntry(
    this.context,
    this.onBack, {
    this.onMove,
    this.onConfirm,
    this.onRelease,
    this.onFreeDrag,
    this.carriedRect,
  });

  final BuildContext context;
  VoidCallback onBack;

  /// Takes the d-pad and stick instead of the highlight, when set.
  void Function(PadDirection direction)? onMove;

  /// Takes A instead of the highlighted control, when set.
  VoidCallback? onConfirm;

  /// Called when a held button ([PadRelease]) is let go.
  void Function(PadButton button)? onRelease;

  /// The stick takes over a carry to drag freely, like a finger: the capture
  /// ends its carry, and says whether the block moved (then the finger
  /// starts on it where it now is; else where R2 was pressed).
  bool Function()? onFreeDrag;

  /// Where the carried block is on screen, asked once a moved block is put
  /// down, so the finger presses it there even if the highlight isn't on
  /// it; null (or no answer) presses the highlighted control.
  Rect? Function()? carriedRect;
}

/// Held R2 on the highlighted control: a block takes it to start being
/// carried ([FocusTap.onGrab]).
class PadGrabIntent extends Intent {
  const PadGrabIntent();
}

/// The captures in force, newest last. Shortcuts listen, so a paused one
/// hides its badge; they hear of a change after the frame, since captures
/// come and go while widgets build.
class PadCaptures extends ChangeNotifier {
  final _entries = <PadCaptureEntry>[];

  PadCaptureEntry? get lastOrNull => _entries.lastOrNull;

  void add(PadCaptureEntry entry) {
    _entries.add(entry);
    _changed();
  }

  void remove(PadCaptureEntry entry) {
    if (_entries.remove(entry)) _changed();
  }

  /// Whether a shortcut in [entry]'s place works now: with no capture, or
  /// inside the newest one.
  bool allows(PadShortcutEntry entry) {
    final capture = _entries.lastOrNull;
    return capture == null || entry.isInside(capture.context);
  }

  var _disposed = false;

  void _changed() {
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      })
      ..scheduleFrame();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
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
  final PadCaptures captures;

  /// Null outside a [GamepadNavigator], as in most widget tests.
  static GamepadScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GamepadScope>();

  @override
  bool updateShouldNotify(GamepadScope oldWidget) => active != oldWidget.active;
}
