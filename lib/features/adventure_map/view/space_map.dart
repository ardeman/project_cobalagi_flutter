import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/learning/view/concepts.dart';
import 'package:cobalagi/core/widgets/paint_transition.dart';
import 'package:cobalagi/features/adventure_map/view/map_connections.dart';

/// One planet on the [SpaceMap]. (The code calls a concept's world an
/// island, as it began; children see planets.)
final class MapIsland {
  const MapIsland({
    required this.conceptId,
    required this.stars,
    required this.solvedLessons,
    required this.totalLessons,
    required this.current,
    required this.locked,
    this.unlocking = false,
  });

  final String conceptId;

  /// 0 to 3, as on the progress report.
  final int stars;
  final int solvedLessons;
  final int totalLessons;
  final bool current;
  final bool locked;

  /// Just reached: its lock and cloud lift away in a burst of stars.
  final bool unlocking;
}

/// The adventure map: planets in a starry sky, joined by a dotted flight path
/// that winds left to right on wide screens and top to bottom (scrolling) on
/// narrow ones. [marker] (the child's avatar) bobs above the current planet.
class SpaceMap extends StatefulWidget {
  const SpaceMap({
    super.key,
    required this.islands,
    required this.marker,
    required this.onOpen,
    this.padding = EdgeInsets.zero,
  });

  final List<MapIsland> islands;

  /// Room at the top and bottom kept clear of planets, for bars that float
  /// over the map; the sky still fills it.
  final EdgeInsets padding;
  final Widget marker;

  /// Opens an island's levels; never called for a locked island.
  final ValueChanged<String> onOpen;

  @override
  State<SpaceMap> createState() => _SpaceMapState();
}

class _SpaceMapState extends State<SpaceMap> {
  /// Made on the first narrow layout, scrolled to the current island.
  ScrollController? _scroll;

  /// Made on the first short wide layout, scrolled to the current island.
  ScrollController? _sideScroll;

  /// The row's last (map width, view width), to recentre when it changes.
  (double, double)? _sideLayout;

  @override
  void dispose() {
    _scroll?.dispose();
    _sideScroll?.dispose();
    super.dispose();
  }

  /// Distance between island centres on phones, in island sizes.
  static const _rowStep = 1.75;

  VoidCallback? _open(int i) => widget.islands[i].locked
      ? null
      : () => widget.onOpen(widget.islands[i].conceptId);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final pad = widget.padding;
      // The height islands may use, between the bars.
      final room = max(0.0, constraints.maxHeight - pad.vertical);
      final wide = width > room * 1.1;
      final n = widget.islands.length;
      // Short and wide (phones held sideways): two rows would crush the
      // islands, so they sit in one row and the sea scrolls sideways.
      final row = wide && room < 420;
      // Island size: as big as fits, but not huge on large tablets, and
      // never squeezed below a comfortable size to fit them all: the sea
      // scrolls sideways instead.
      final size = row
          ? (room / 2.1).clamp(56.0, 150.0).toDouble()
          : wide
          ? min(
              room * 0.24,
              max(width / (max(n, 1) * 2.2), 104.0),
            ).clamp(72.0, 170.0).toDouble()
          : min(width * 0.3, 150.0).clamp(72.0, 150.0).toDouble();
      // Wide zigzag: islands spread over the screen, at least 1.8 sizes
      // apart, with 13% of the screen as a margin at each end.
      final step = n < 2
          ? 0.0
          : max(width * 0.74 / (n - 1), size * 1.8).toDouble();
      final mapWidth = row
          ? max(width, size * 2.6 + max(n - 1, 0) * size * 2.2)
          : wide
          ? max(width, step * (n - 1) + width * 0.26)
          : width;
      final height = wide
          ? constraints.maxHeight
          : max(
              constraints.maxHeight,
              pad.vertical + size * 1.45 + max(n - 1, 0) * size * _rowStep,
            );
      final centres = [
        for (var i = 0; i < n; i++)
          row
              ? Offset(
                  mapWidth / 2 + (i - (n - 1) / 2) * size * 2.2,
                  // Centred between the bars: island and label, ~1.9 sizes.
                  pad.top + max(0.0, (room - size * 1.9) / 2) + size * 0.95,
                )
              : wide
              ? Offset(
                  n == 1
                      ? width / 2
                      : (mapWidth - step * (n - 1)) / 2 + i * step,
                  pad.top + room * (i.isEven ? 0.36 : 0.64),
                )
              : Offset(
                  width * (i.isEven ? 0.27 : 0.73),
                  pad.top + size * 1.1 + i * size * _rowStep,
                ),
      ];
      // The path is bright up to the furthest island the child can open.
      final reached = widget.islands.lastIndexWhere((i) => !i.locked);

      final map = SizedBox(
        width: mapWidth,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Its own layer: the sky is costly (hundreds of stars, glowing
            // clouds) and must not repaint whenever something on the map
            // animates, such as the bobbing marker.
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SkyPainter(
                    reached: reached,
                    paths: mapConnections(
                      centres: centres,
                      islandSize: size,
                      wide: wide,
                    ),
                  ),
                ),
              ),
            ),
            for (var i = 0; i < n; i++) ...[
              Positioned(
                left: centres[i].dx - size,
                top: centres[i].dy - size * 0.85,
                width: size * 2,
                child: _Celebrated(
                  active: widget.islands[i].unlocking,
                  size: size,
                  child: _Island(
                    island: widget.islands[i],
                    size: size,
                    marker: widget.marker,
                    // Phones show the label beside the island instead.
                    label: wide,
                    onTap: _open(i),
                  ),
                ),
              ),
              if (!wide)
                // Beside the island, on the side away from the screen edge,
                // so the path runs straight from shore to shore.
                Positioned(
                  top: centres[i].dy - size * 0.6,
                  height: size,
                  left: i.isEven ? centres[i].dx + size * 0.8 + 4 : 12,
                  right: i.isEven ? 12 : width - centres[i].dx + size * 0.8 + 4,
                  child: Align(
                    alignment: i.isEven
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _IslandLabel(
                        island: widget.islands[i],
                        size: size,
                        onTap: _open(i),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
      final current = widget.islands.indexWhere((i) => i.current);
      if (row || mapWidth > width) {
        // Start with the current island in the middle, and again whenever
        // the layout changes (rotating, or the first real size).
        final double offset = current < 0
            ? 0
            : (centres[current].dx - width / 2)
                  .clamp(0.0, max(0.0, mapWidth - width))
                  .toDouble();
        final controller = _sideScroll ??= ScrollController(
          initialScrollOffset: offset,
        );
        if (_sideLayout != (mapWidth, width)) {
          _sideLayout = (mapWidth, width);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (controller.hasClients) controller.jumpTo(offset);
          });
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: controller,
          child: map,
        );
      }
      if (wide) return map;
      // Narrow screens scroll; start with the current island in view.
      final double offset = current < 0
          ? 0
          : (centres[current].dy - pad.top - room / 2)
                .clamp(0.0, max(0.0, height - constraints.maxHeight))
                .toDouble();
      return SingleChildScrollView(
        controller: _scroll ??= ScrollController(initialScrollOffset: offset),
        child: map,
      );
    },
  );
}

/// The night sky, its stars and glowing clouds, and the dotted flight path
/// between planets.
class _SkyPainter extends CustomPainter {
  _SkyPainter({required this.paths, required this.reached});

  /// Where the path leaves one island and reaches the next.
  final List<Path> paths;
  final int reached;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1F4E), Color(0xFF2B2468), Color(0xFF3B2A78)],
        ).createShader(rect),
    );

    final random = Random(7);
    // Soft glowing clouds of colour (nebulas), far away.
    final clouds = (size.width * size.height / 260000).round().clamp(2, 8);
    for (var i = 0; i < clouds; i++) {
      final at = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = 120.0 + random.nextDouble() * 160;
      final tint = const [
        Color(0xFF8E6CFF),
        Color(0xFF3FC5E8),
        Color(0xFFFF7AB6),
      ][i % 3];
      canvas.drawCircle(
        at,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [tint.withValues(alpha: 0.22), tint.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: at, radius: radius)),
      );
    }

    // Stars: dots scattered at fixed places, a few bigger ones sparkling.
    final stars = (size.width * size.height / 5000).round().clamp(40, 400);
    for (var i = 0; i < stars; i++) {
      final at = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final bright = random.nextDouble();
      if (i % 23 == 0) {
        final r = 5.0 + bright * 4;
        final sparkle = Path()
          ..moveTo(at.dx, at.dy - r)
          ..quadraticBezierTo(at.dx, at.dy, at.dx + r, at.dy)
          ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + r)
          ..quadraticBezierTo(at.dx, at.dy, at.dx - r, at.dy)
          ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - r);
        canvas.drawPath(sparkle, Paint()..color = const Color(0xFFFFF3C4));
      } else {
        canvas.drawCircle(
          at,
          0.8 + bright * 1.4,
          Paint()..color = Colors.white.withValues(alpha: 0.35 + bright * 0.55),
        );
      }
    }

    // The flight path: dots along a gentle curve from planet to planet.
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final unlocked = i + 1 <= reached;
      final color = unlocked
          ? const Color(0xFFFFE07A)
          : const Color(0xFFE6E9FF).withValues(alpha: 0.35);
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: unlocked ? 0.18 : 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = unlocked ? 12 : 8
          ..strokeCap = StrokeCap.round,
      );
      for (final metric in path.computeMetrics()) {
        final count = max(2, (metric.length / 18).round());
        for (var dot = 0; dot < count; dot++) {
          final distance = metric.length * (dot + 0.5) / count;
          final at = metric.getTangentForOffset(distance)!.position;
          if (unlocked) {
            canvas.drawCircle(
              at + const Offset(0, 1.5),
              5,
              Paint()..color = const Color(0xFFFFC83D).withValues(alpha: 0.25),
            );
          }
          canvas.drawCircle(at, unlocked ? 4.5 : 3.2, Paint()..color = color);
          if (unlocked) {
            canvas.drawCircle(
              at - const Offset(1, 1),
              1.4,
              Paint()..color = Colors.white.withValues(alpha: 0.8),
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.reached != reached || old.paths != paths;
}

/// A planet with the concept's emblem, its stars, name and levels.
class _Island extends StatelessWidget {
  const _Island({
    required this.island,
    required this.size,
    required this.marker,
    required this.onTap,
    this.label = true,
  });

  final MapIsland island;
  final double size;
  final Widget marker;
  final VoidCallback? onTap;

  /// Stars, name and lessons below the island; phones place an
  /// [_IslandLabel] beside it instead.
  final bool label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locked = island.locked;
    final color = locked
        ? const Color(0xFF8A90B4)
        : conceptColor(island.conceptId);
    final emblem = size * 0.8;
    return Semantics(
      button: !locked,
      label: conceptName(l10n, island.conceptId),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: !locked,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size * 1.6,
                height: size * 1.05,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Every other planet wears a ring, its back half
                    // behind the planet and its front half across it.
                    if (_ringed(island.conceptId))
                      Positioned(
                        bottom: size * 0.22 + emblem / 2 - size * 0.2,
                        child: CustomPaint(
                          size: Size(size * 1.5, size * 0.4),
                          painter: _Ring(color: color, front: false),
                        ),
                      ),
                    // The planet, with the concept's emblem on it.
                    Positioned(
                      bottom: size * 0.22,
                      child: Container(
                        width: emblem,
                        height: emblem,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.4, -0.45),
                            radius: 1.1,
                            colors: [
                              Color.lerp(color, Colors.white, 0.35)!,
                              color,
                              Color.lerp(color, Colors.black, 0.35)!,
                            ],
                            stops: const [0, 0.55, 1],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: emblem * 0.05,
                            color: island.current
                                ? const Color(0xFFFFD54F)
                                : Colors.white.withValues(alpha: 0.55),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: island.current
                                  ? const Color(0xAAFFD54F)
                                  : color.withValues(alpha: 0.35),
                              blurRadius: island.current ? 22 : 14,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _Craters(
                            Color.lerp(color, Colors.black, 0.25)!,
                          ),
                          child: Icon(
                            locked
                                ? Icons.lock_rounded
                                : conceptIcon(island.conceptId),
                            size: emblem * 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (_ringed(island.conceptId))
                      Positioned(
                        bottom: size * 0.22 + emblem / 2 - size * 0.2,
                        child: IgnorePointer(
                          child: CustomPaint(
                            size: Size(size * 1.5, size * 0.4),
                            painter: _Ring(color: color, front: true),
                          ),
                        ),
                      ),
                    // Space dust over planets the child can't reach yet.
                    if (locked)
                      Positioned(
                        bottom: size * 0.5,
                        right: size * 0.1,
                        child: Icon(
                          Icons.cloud_rounded,
                          size: size * 0.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    if (island.current)
                      Positioned(
                        bottom: size * 0.22 + emblem * 0.7,
                        child: _Bobbing(child: marker),
                      ),
                  ],
                ),
              ),
              if (label) ...[
                SizedBox(height: size * 0.04),
                _IslandLabel(island: island, size: size),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An island's stars, name and solved lessons.
class _IslandLabel extends StatelessWidget {
  const _IslandLabel({required this.island, required this.size, this.onTap});

  final MapIsland island;
  final double size;

  /// Set when the label stands apart from its island, so it opens it too.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: Colors.white,
      shadows: const [Shadow(color: Color(0xAA0B0D2A), blurRadius: 6)],
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                i < island.stars
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: size * 0.2,
                color: const Color(0xFFFFC83D),
                shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
              ),
          ],
        ),
        Text(
          conceptName(l10n, island.conceptId),
          textAlign: TextAlign.center,
          style: textStyle,
        ),
        Text(
          '${island.solvedLessons}/${island.totalLessons}',
          style: textStyle?.copyWith(
            fontSize: (textStyle.fontSize ?? 16) * 0.85,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    if (onTap == null) return column;
    // The island itself carries the name for screen readers.
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: column,
      ),
    );
  }
}

/// Whether a planet wears a ring: about every other one, always the same.
bool _ringed(String conceptId) =>
    conceptId.codeUnits.fold(0, (a, b) => a + b).isOdd;

/// A planet's ring, seen at a tilt: [front] draws the half that crosses
/// in front of the planet, otherwise the half behind it.
class _Ring extends CustomPainter {
  const _Ring({required this.color, required this.front});

  final Color color;
  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(size.height * 0.1);
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(-0.18)
      ..translate(-size.width / 2, -size.height / 2)
      ..drawArc(
        rect,
        front ? 0 : pi,
        pi,
        false,
        Paint()
          ..color = Color.lerp(color, Colors.white, 0.55)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.height * 0.16
          ..strokeCap = StrokeCap.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_Ring old) => old.color != color || old.front != front;
}

/// A few round dents on a planet's face.
class _Craters extends CustomPainter {
  const _Craters(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.45);
    final d = size.shortestSide;
    for (final (x, y, r) in const [
      (0.72, 0.28, 0.08),
      (0.24, 0.7, 0.07),
      (0.68, 0.78, 0.05),
    ]) {
      canvas.drawCircle(Offset(x * d, y * d), r * d, paint);
    }
  }

  @override
  bool shouldRepaint(_Craters old) => old.color != color;
}

/// Gently moves [child] up and down: "you are here".
class _Bobbing extends StatefulWidget {
  const _Bobbing({required this.child});

  final Widget child;

  @override
  State<_Bobbing> createState() => _BobbingState();
}

class _BobbingState extends State<_Bobbing>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  Widget build(BuildContext context) => PaintTransition(
    animation: _curve,
    transform: PaintTransition.translateY(-6),
    child: widget.child,
  );
}

/// The opening of a newly reached island: the island bounces in while its
/// lock and cloud lift away and golden stars burst around it. Shown still,
/// at its end, when the device asks for less motion.
class _Celebrated extends StatelessWidget {
  const _Celebrated({
    required this.active,
    required this.size,
    required this.child,
  });

  final bool active;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2200),
      builder: (context, t, child) {
        // The island bounces up to full size in the first half.
        final grow = Curves.elasticOut.transform(min(1, t * 2));
        // The lock and cloud lift away early; the stars spread and fade.
        final lift = Curves.easeOut.transform(min(1, t * 1.6));
        final burst = Curves.easeOutCubic.transform(t);
        final emblemTop = size * 0.05;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Transform.scale(
              scale: 0.7 + 0.3 * grow,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
            for (var k = 0; k < 10; k++)
              Positioned(
                top:
                    emblemTop +
                    size * 0.35 +
                    sin(k * 2 * pi / 10) * size * (0.2 + 0.9 * burst),
                left:
                    size +
                    cos(k * 2 * pi / 10) * size * (0.2 + 1.0 * burst) -
                    size * 0.1,
                child: Opacity(
                  opacity: (1 - burst).clamp(0, 1),
                  child: Icon(
                    Icons.star_rounded,
                    size: size * 0.2,
                    color: const Color(0xFFFFC83D),
                  ),
                ),
              ),
            Positioned(
              top: emblemTop - size * 0.9 * lift,
              child: Opacity(
                opacity: (1 - lift).clamp(0, 1),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.cloud_rounded,
                      size: size * 0.9,
                      color: Colors.white,
                    ),
                    Icon(
                      Icons.lock_rounded,
                      size: size * 0.32,
                      color: Colors.blueGrey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
