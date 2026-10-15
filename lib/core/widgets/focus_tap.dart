import 'package:flutter/widgets.dart';

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
  });

  /// Null makes it neither tappable nor focusable.
  final VoidCallback? onTap;
  final HitTestBehavior? behavior;
  final Widget child;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    enabled: onTap != null,
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          onTap?.call();
          return null;
        },
      ),
    },
    child: GestureDetector(onTap: onTap, behavior: behavior, child: child),
  );
}
