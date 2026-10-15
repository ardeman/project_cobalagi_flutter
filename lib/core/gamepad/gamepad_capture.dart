import 'package:flutter/widgets.dart';

import 'package:cobalagi/core/gamepad/gamepad_scope.dart';

/// Takes the controller while it is on screen (a guided tour): the screen's
/// shortcuts wait, B calls [onBack], and the highlight stays inside [child].
class GamepadCapture extends StatefulWidget {
  const GamepadCapture({super.key, required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  State<GamepadCapture> createState() => _GamepadCaptureState();
}

class _GamepadCaptureState extends State<GamepadCapture> {
  List<PadCaptureEntry>? _captures;
  late final _entry = PadCaptureEntry(widget.onBack);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final captures = GamepadScope.maybeOf(context)?.captures;
    if (identical(captures, _captures)) return;
    _captures?.remove(_entry);
    _captures = captures?..add(_entry);
  }

  @override
  void didUpdateWidget(GamepadCapture oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.onBack = widget.onBack;
  }

  @override
  void dispose() {
    _captures?.remove(_entry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FocusScope(autofocus: true, child: widget.child);
}
