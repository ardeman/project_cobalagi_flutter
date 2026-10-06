import 'dart:ui';

import 'package:flutter/material.dart';

/// Which side of the screen a [GlassBar] sits on; its hairline faces the
/// content.
enum GlassEdge { top, bottom }

/// A full-width bar that turns to frosted glass while content scrolls under
/// it ([under]) and stays clear otherwise. High-contrast mode uses an opaque
/// surface instead of blur.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.under,
    required this.edge,
    required this.child,
  });

  final bool under;
  final GlassEdge edge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final surface = theme.colorScheme.surface;
    final hairline = BorderSide(
      color: highContrast
          ? theme.colorScheme.outline
          : Colors.white.withValues(alpha: dark ? 0.18 : 0.7),
    );
    final tint = DecoratedBox(
      decoration: BoxDecoration(
        color: highContrast
            ? surface
            : surface.withValues(alpha: dark ? 0.62 : 0.5),
        border: edge == GlassEdge.top
            ? Border(bottom: hairline)
            : Border(top: hairline),
      ),
    );
    return Stack(
      // The content gets the bar's own width, so it lines up like it would
      // without the glass behind it.
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          // Fully transparent paints nothing, so a clear bar costs no blur.
          child: AnimatedOpacity(
            opacity: under ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: ClipRect(
              child: highContrast
                  ? tint
                  : BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: tint,
                    ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
