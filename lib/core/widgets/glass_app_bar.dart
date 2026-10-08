import 'package:flutter/material.dart';

import 'glass_bar.dart';

/// An app bar that content scrolls under, frosted while it does. Use it with
/// `Scaffold(extendBodyBehindAppBar: true)` and pad the body's scroll view by
/// `MediaQuery.paddingOf(context)` (see [belowBars]).
class GlassAppBar extends StatefulWidget implements PreferredSizeWidget {
  const GlassAppBar({super.key, this.leading, this.title, this.actions});

  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;

  /// Same room as the game screen's top bar: 64 dp buttons with a 16 dp
  /// margin around them.
  static const height = 96.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  State<GlassAppBar> createState() => _GlassAppBarState();
}

class _GlassAppBarState extends State<GlassAppBar> {
  ScrollNotificationObserverState? _observer;
  var _under = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        axisDirectionToAxis(notification.metrics.axisDirection) !=
            Axis.vertical) {
      return;
    }
    final under = notification.metrics.extentBefore > 0;
    if (under != _under) setState(() => _under = under);
  }

  @override
  Widget build(BuildContext context) => GlassBar(
    under: _under,
    edge: GlassEdge.top,
    child: AppBar(
      toolbarHeight: GlassAppBar.height,
      leadingWidth: 64 + 16 + 8,
      leading: widget.leading == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Center(child: widget.leading),
            ),
      titleSpacing: widget.leading == null ? 16 : 8,
      title: widget.title,
      // The same 16 dp from the edge as the leading button.
      actions: [...?widget.actions, const SizedBox(width: 16)],
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
    ),
  );
}

/// [padding] plus the space a [GlassAppBar] and the system bars take, for a
/// scroll view whose content passes under them. [context] must be below the
/// Scaffold (use a Builder), or the app bar's height is missing.
EdgeInsets belowBars(BuildContext context, EdgeInsets padding) {
  final insets = MediaQuery.paddingOf(context);
  return padding + EdgeInsets.only(top: insets.top, bottom: insets.bottom);
}
