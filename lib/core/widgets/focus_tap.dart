import 'package:flutter/widgets.dart';

import 'package:cobalagi/core/gamepad/gamepad_scope.dart';

/// A tap target that a controller or keyboard reaches and presses too: it
/// takes focus (the highlight can jump to it), and A, Enter or Space taps it.
/// Use it instead of a bare `GestureDetector(onTap:)` on anything a child
/// taps.
class FocusTap extends StatelessWidget {
  const FocusTap({
    super.key,
    required this.onTap,
    required this.child,
    this.behavior,
    this.focusNode,
    this.onGrab,
  });

  /// Null makes it neither tappable nor focusable.
  final VoidCallback? onTap;
  final HitTestBehavior? behavior;

  /// A node the owner keeps, to move focus to this target itself.
  final FocusNode? focusNode;

  /// What holding R2 on it does: start carrying it. Null: nothing, and the
  /// highlight shows no R2.
  final VoidCallback? onGrab;
  final Widget child;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    enabled: onTap != null,
    focusNode: focusNode,
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          onTap?.call();
          return null;
        },
      ),
      if (onGrab != null)
        PadGrabIntent: CallbackAction<PadGrabIntent>(
          onInvoke: (_) {
            onGrab?.call();
            return null;
          },
        ),
    },
    child: GestureDetector(onTap: onTap, behavior: behavior, child: child),
  );
}
