import 'package:flutter/widgets.dart';

import 'package:cobalagi/core/gamepad/screen_keyboard_io.dart'
    if (dart.library.js_interop) 'package:cobalagi/core/gamepad/screen_keyboard_web.dart'
    as platform;

/// An on-screen keyboard the app has to open and close itself, drawn over
/// the app instead of making room for itself.
class ScreenKeyboard {
  const ScreenKeyboard({
    required this.show,
    required this.hide,
    required this.covers,
  });

  final VoidCallback show;
  final VoidCallback hide;

  /// How much of the screen's height it covers from the bottom, at most.
  final double covers;
}

/// Steam's keyboard on the Steam Deck (and in Big Picture), which doesn't
/// open or close by itself for a non-Steam game; null where the system's own
/// keyboard already comes and goes with a text field.
ScreenKeyboard? steamKeyboard() => platform.steamKeyboard();

/// Shows [keyboard] whenever a text field below gets focus, by touch or by
/// the controller's highlight, and hides it when focus leaves the field (a
/// dialog's Save or Cancel, or the highlight moving on). While it shows, the
/// app below sees it as the system keyboard ([MediaQueryData.viewInsets]),
/// so dialogs move above it and fields scroll clear of it.
class ScreenKeyboardOnFocus extends StatefulWidget {
  const ScreenKeyboardOnFocus({super.key, this.keyboard, required this.child});

  /// Null does nothing (tests, and every platform but the Steam Deck).
  final ScreenKeyboard? keyboard;
  final Widget child;

  @override
  State<ScreenKeyboardOnFocus> createState() => _ScreenKeyboardOnFocusState();
}

class _ScreenKeyboardOnFocusState extends State<ScreenKeyboardOnFocus> {
  FocusNode? _focused;
  bool _shown = false;

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
    final keyboard = widget.keyboard;
    if (keyboard == null) return;
    final context = node?.context;
    final typing =
        context != null &&
        context.mounted &&
        context.findAncestorWidgetOfExactType<EditableText>() != null;
    if (typing) {
      keyboard.show();
    } else if (_shown) {
      keyboard.hide();
    }
    if (typing != _shown) setState(() => _shown = typing);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = widget.keyboard;
    if (keyboard == null || !_shown) return widget.child;
    final media = MediaQuery.of(context);
    final covered = media.size.height * keyboard.covers;
    if (media.viewInsets.bottom >= covered) return widget.child;
    return MediaQuery(
      data: media.copyWith(
        viewInsets: media.viewInsets.copyWith(bottom: covered),
      ),
      child: widget.child,
    );
  }
}
