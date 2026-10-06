import 'package:flutter/material.dart';

/// Static ambient colours behind the app's translucent surfaces.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF102D37), Color(0xFF172A39), Color(0xFF30283D)]
              : const [Color(0xFFD9F4F0), Color(0xFFEAF3FA), Color(0xFFFFE9DC)],
        ),
      ),
      child: child,
    );
  }
}
