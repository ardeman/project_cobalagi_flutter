import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// Shows a dialog over a softly blurred screen; the dialog's translucent
/// panel (see `dialogTheme` in `app_theme.dart`) lets that blur through.
/// High-contrast mode keeps a plain dimmed screen and an opaque dialog.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  barrierColor: Colors.black.withValues(alpha: 0.18),
  builder: (context) => _GlassBackdrop(child: builder(context)),
);

/// Shows a modal bottom sheet whose panel is frosted glass over the screen.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  backgroundColor: Colors.transparent,
  clipBehavior: Clip.antiAlias,
  // The panel draws the handle itself, so it sits on the glass too.
  // The sheet is at most 640 dp wide and centred, so it never reaches a side
  // of the screen held sideways: a camera cutout's side padding would only
  // push its content off centre.
  builder: (context) => MediaQuery.removePadding(
    context: context,
    removeLeft: MediaQuery.sizeOf(context).width > 640,
    removeRight: MediaQuery.sizeOf(context).width > 640,
    child: _GlassPanel(handle: showDragHandle, child: builder(context)),
  ),
);

class _GlassBackdrop extends StatelessWidget {
  const _GlassBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.highContrastOf(context)) {
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(
          dialogTheme: theme.dialogTheme.copyWith(
            backgroundColor: theme.colorScheme.surface,
          ),
        ),
        child: child,
      );
    }
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: child,
    );
  }
}

/// Fills the sheet with liquid glass under a light tint.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.handle, required this.child});

  final bool handle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final content = handle
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(child: child),
            ],
          )
        : child;
    if (MediaQuery.highContrastOf(context)) {
      return ColoredBox(color: surface, child: content);
    }
    // Liquid glass behind the sheet. It reaches below the screen, so only
    // its top corners show, rounded like the sheet's own clip.
    return Stack(
      // The sheet's own clip trims the overhang, not this stack.
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: -48,
          child: LiquidGlassLens(
            style: LiquidGlassStyle(
              shape: const LiquidGlassShape.continuousRoundedRectangle(
                cornerRadius: 28,
                borderWidth: 1.2,
              ),
              appearance: LiquidGlassAppearance(
                color: Color.lerp(
                  surface,
                  Colors.white,
                  dark ? 0.06 : 0.4,
                )!.withValues(alpha: dark ? 0.72 : 0.6),
                blur: const LiquidGlassBlur(sigmaX: 8, sigmaY: 8),
              ),
              refraction: const LiquidGlassRefraction(
                distortion: 0.2,
                distortionWidth: 36,
                chromaticAberration: 0.002,
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }
}
