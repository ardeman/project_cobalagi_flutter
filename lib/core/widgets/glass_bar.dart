import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// Which side of the screen a [GlassBar] sits on: the side its blur is
/// strongest at.
enum GlassEdge { top, bottom }

/// A full-width bar that blurs what scrolls under it ([under]), strongest at
/// the screen edge like iOS, and stays clear otherwise. High-contrast mode
/// uses an opaque surface with a hairline instead.
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
    final hairline = BorderSide(color: theme.colorScheme.outline);
    final tint = DecoratedBox(
      decoration: BoxDecoration(color: surface, border: _edge(edge, hairline)),
    );
    return Stack(
      // The content gets the bar's own width, so it lines up like it would
      // without the glass behind it. The blur reaches past the bar.
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        if (highContrast)
          Positioned.fill(
            // Fully transparent paints nothing, so a clear bar costs
            // nothing.
            child: AnimatedOpacity(
              opacity: under ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: tint,
            ),
          )
        else
          // A scroll edge, like iOS: what passes under the bar blurs more
          // the closer it is to the screen edge, under a light tint, with
          // no line. It reaches [_fadeOut] past the bar, so the blur eases
          // out instead of ending on an edge. It fades in by its own blur
          // and tint, never by opacity.
          Positioned(
            left: 0,
            right: 0,
            top: edge == GlassEdge.top ? 0 : -_fadeOut,
            bottom: edge == GlassEdge.top ? -_fadeOut : 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: under ? 1 : 0),
              duration: const Duration(milliseconds: 200),
              builder: (context, t, _) => t == 0
                  // Clear: no blur pass at all.
                  ? const SizedBox.shrink()
                  : LiquidGlassScrollEdge(
                      edge: edge == GlassEdge.top
                          ? LiquidGlassEdge.top
                          : LiquidGlassEdge.bottom,
                      color: surface.withValues(alpha: (dark ? 0.7 : 0.6) * t),
                      blur: 10 * t,
                    ),
            ),
          ),
        child,
      ],
    );
  }

  /// How far the blur reaches past the bar as it fades out.
  static const _fadeOut = 28.0;
}

/// The hairline on the side of the bar that faces the content.
Border _edge(GlassEdge edge, BorderSide side) =>
    edge == GlassEdge.top ? Border(bottom: side) : Border(top: side);
