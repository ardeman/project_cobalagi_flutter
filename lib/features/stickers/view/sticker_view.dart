import 'package:flutter/material.dart';

/// A round die-cut sticker: an emblem on a coloured disc with a white edge,
/// tilted a little like a real one. Not yet earned, it is a faint outline.
/// A [fresh] sticker pops in once, with a few sparkles.
class StickerView extends StatelessWidget {
  const StickerView({
    super.key,
    required this.icon,
    required this.color,
    required this.earned,
    required this.size,
    this.tilt = 0,
    this.fresh = false,
  });

  final IconData icon;
  final Color color;
  final bool earned;
  final double size;

  /// Turns, e.g. 0.02 for a slight clockwise tilt.
  final double tilt;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!earned) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(color: scheme.outlineVariant, width: 3),
        ),
        child: Icon(icon, size: size * 0.45, color: scheme.outlineVariant),
      );
    }
    final sticker = RotationTransition(
      turns: AlwaysStoppedAnimation(tilt),
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.06),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: size * 0.08,
              offset: Offset(0, size * 0.04),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [Color.lerp(color, Colors.white, 0.3)!, color],
            ),
          ),
          child: Icon(icon, size: size * 0.48, color: Colors.white),
        ),
      ),
    );
    if (!fresh || MediaQuery.disableAnimationsOf(context)) return sticker;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      builder: (context, t, child) {
        final grow = Curves.elasticOut.transform((t * 1.4).clamp(0, 1));
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(scale: grow, child: child),
            for (var i = 0; i < 6; i++)
              Transform.translate(
                offset: Offset.fromDirection(
                  i * 1.047 + 0.3,
                  size * (0.45 + 0.35 * t),
                ),
                child: Opacity(
                  opacity: (1 - t).clamp(0, 1),
                  child: Icon(
                    Icons.star_rounded,
                    size: size * 0.18,
                    color: const Color(0xFFFFC83D),
                  ),
                ),
              ),
          ],
        );
      },
      child: sticker,
    );
  }
}
