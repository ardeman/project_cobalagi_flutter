import 'package:flutter/widgets.dart';

import 'package:cobalagi/core/gamepad/screen_keyboard_io.dart'
    if (dart.library.js_interop) 'package:cobalagi/core/gamepad/screen_keyboard_web.dart'
    as platform;

/// Asks the system to show its on-screen keyboard.
typedef ShowScreenKeyboard = void Function();

/// Steam's keyboard on the Steam Deck (and in Big Picture), which doesn't
/// open by itself for a non-Steam game; null where the system's own
/// keyboard already opens for a text field.
ShowScreenKeyboard? steamKeyboard() => platform.steamKeyboard();

/// Calls [show] whenever a text field below gets focus, by touch or by the
/// controller's highlight.
class ScreenKeyboardOnFocus extends StatefulWidget {
  const ScreenKeyboardOnFocus({super.key, this.show, required this.child});

  /// Null does nothing (tests, and every platform but the Steam Deck).
  final ShowScreenKeyboard? show;
  final Widget child;

  @override
  State<ScreenKeyboardOnFocus> createState() => _ScreenKeyboardOnFocusState();
}

class _ScreenKeyboardOnFocusState extends State<ScreenKeyboardOnFocus> {
  FocusNode? _focused;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    final node = FocusManager.instance.primaryFocus;
    // The listener also hears focus highlight changes: show it once per
    // field.
    if (identical(node, _focused)) return;
    _focused = node;
    final show = widget.show;
    final context = node?.context;
    if (show == null || context == null || !context.mounted) return;
    if (context.findAncestorWidgetOfExactType<EditableText>() != null) show();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
