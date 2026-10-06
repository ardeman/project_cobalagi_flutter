import 'dart:ui';

import 'package:flutter/material.dart';

/// A bounded frosted panel. Blur is clipped to the panel, and high-contrast
/// mode uses an opaque surface so the background cannot affect readability.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 24,
    this.tint,
    this.blur = true,
    this.borderColor,
    this.borderWidth = 1.2,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final bool blur;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final base = tint ?? theme.colorScheme.surface;
    final borderRadius = BorderRadius.circular(radius);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highContrast
              ? [base, base]
              : [
                  Color.lerp(
                    base,
                    Colors.white,
                    dark ? 0.08 : 0.45,
                  )!.withValues(alpha: dark ? 0.88 : 0.84),
                  base.withValues(alpha: dark ? 0.78 : 0.64),
                ],
        ),
        border: Border.all(
          color:
              borderColor ??
              (highContrast
                  ? theme.colorScheme.outline
                  : Colors.white.withValues(alpha: dark ? 0.22 : 0.78)),
          width: borderWidth,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164F59).withValues(alpha: dark ? 0.2 : 0.09),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: blur && !highContrast
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: panel,
              )
            : panel,
      ),
    );
  }
}
