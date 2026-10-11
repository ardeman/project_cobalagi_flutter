import 'package:flutter/material.dart';

/// A round die-cut sticker: an emblem on a coloured disc with a white edge,
/// tilted a little like a real one. Not yet earned, it is a faint outline.
/// A [gold] sticker (every star collected) has a gold edge, a shine and a
/// star badge. A [fresh] sticker pops in once, with a few sparkles.
class StickerView extends StatelessWidget {
  const StickerView({
    super.key,
    required this.icon,
    required this.color,
    required this.earned,
    required this.size,
    this.tilt = 0,
    this.fresh = false,
    this.gold = false,
  });

  final IconData icon;
  final Color color;
  final bool earned;
  final double size;

  /// Turns, e.g. 0.02 for a slight clockwise tilt.
  final double tilt;
  final bool fresh;
  final bool gold;

  static const _goldLight = Color(0xFFFFE680);
  static const _goldMid = Color(0xFFFFC83D);
  static const _goldDeep = Color(0xFFD99A00);

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
    final disc = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.3)!, color],
        ),
      ),
      child: Icon(icon, size: size * 0.48, color: Colors.white),
    );
    final sticker = RotationTransition(
      turns: AlwaysStoppedAnimation(tilt),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * (gold ? 0.08 : 0.06)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold ? null : Colors.white,
              // Gold foil: light and deep bands around the edge.
              gradient: gold
                  ? const SweepGradient(
                      colors: [
                        _goldLight,
                        _goldDeep,
                        _goldMid,
                        _goldLight,
                        _goldDeep,
                        _goldLight,
                      ],
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: gold
                      ? _goldDeep.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: size * (gold ? 0.14 : 0.08),
                  offset: Offset(0, size * 0.04),
                ),
              ],
            ),
            child: gold
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      disc,
                      // A glossy band across the face.
                      ClipOval(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.3, 0.42, 0.54],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : disc,
          ),
          if (gold)
            Positioned(
              right: -size * 0.04,
              top: -size * 0.04,
              child: Container(
                width: size * 0.36,
                height: size * 0.36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _goldMid,
                  border: Border.all(color: Colors.white, width: size * 0.03),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: size * 0.05,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: size * 0.26,
                  color: Colors.white,
                ),
              ),
            ),
        ],
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
                    color: _goldMid,
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
