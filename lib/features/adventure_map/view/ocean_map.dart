import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/learning/view/concepts.dart';
import 'package:cobalagi/features/adventure_map/view/map_connections.dart';

/// One island on the [OceanMap].
final class MapIsland {
  const MapIsland({
    required this.conceptId,
    required this.stars,
    required this.solvedLessons,
    required this.totalLessons,
    required this.current,
    required this.locked,
  });

  final String conceptId;

  /// 0 to 3, as on the progress report.
  final int stars;
  final int solvedLessons;
  final int totalLessons;
  final bool current;
  final bool locked;
}

/// The adventure map: islands on the sea, joined by a dotted path that winds
/// left to right on wide screens and top to bottom (scrolling) on narrow ones.
/// [marker] (the child's avatar) bobs above the current island.
class OceanMap extends StatefulWidget {
  const OceanMap({
    super.key,
    required this.islands,
    required this.marker,
    required this.onOpen,
    this.padding = EdgeInsets.zero,
  });

  final List<MapIsland> islands;

  /// Space at the top and bottom kept clear of islands, for bars that float
  /// over the map; the sea still fills it.
  final EdgeInsets padding;
  final Widget marker;

  /// Opens an island's levels; never called for a locked island.
  final ValueChanged<String> onOpen;

  @override
  State<OceanMap> createState() => _OceanMapState();
}

class _OceanMapState extends State<OceanMap> {
  /// Made on the first narrow layout, scrolled to the current island.
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final pad = widget.padding;
      // The height islands may use, between the bars.
      final room = max(0.0, constraints.maxHeight - pad.vertical);
      final wide = width > room * 1.1;
      final n = widget.islands.length;
      // Island size: as big as fits, but not huge on large tablets.
      final size = wide
          ? min(
              room * 0.24,
              width / (max(n, 1) * 2.2),
            ).clamp(72.0, 170.0).toDouble()
          : min(width * 0.32, 150.0).clamp(72.0, 150.0).toDouble();
      final height = wide
          ? constraints.maxHeight
          : max(
              constraints.maxHeight,
              pad.vertical + size * 0.9 + n * size * 2.35,
            );
      final centres = [
        for (var i = 0; i < n; i++)
          wide
              ? Offset(
                  width * (n == 1 ? 0.5 : 0.13 + 0.74 * i / (n - 1)),
                  pad.top + room * (i.isEven ? 0.36 : 0.64),
                )
              : Offset(
                  width * (i.isEven ? 0.3 : 0.7),
                  pad.top + size * 1.15 + i * size * 2.35,
                ),
      ];
      // The path is bright up to the furthest island the child can open.
      final reached = widget.islands.lastIndexWhere((i) => !i.locked);

      final map = SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SeaPainter(
                  reached: reached,
                  paths: mapConnections(
                    centres: centres,
                    islandSize: size,
                    wide: wide,
                  ),
                ),
              ),
            ),
            for (var i = 0; i < n; i++)
              Positioned(
                left: centres[i].dx - size,
                top: centres[i].dy - size * 0.85,
                width: size * 2,
                child: _Island(
                  island: widget.islands[i],
                  size: size,
                  marker: widget.marker,
                  onTap: widget.islands[i].locked
                      ? null
                      : () => widget.onOpen(widget.islands[i].conceptId),
                ),
              ),
          ],
        ),
      );
      if (wide) return map;
      // Narrow screens scroll; start with the current island in view.
      final current = widget.islands.indexWhere((i) => i.current);
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

/// The sea, its little waves and the dotted path between islands.
class _SeaPainter extends CustomPainter {
  _SeaPainter({required this.paths, required this.reached});

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
          colors: [Color(0xFF8FE3F0), Color(0xFF4FC3DC)],
        ).createShader(rect),
    );

    // Waves: small arcs scattered at fixed places.
    final random = Random(7);
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final waves = (size.width * size.height / 26000).round().clamp(12, 80);
    for (var i = 0; i < waves; i++) {
      final at = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final w = 14.0 + random.nextDouble() * 12;
      final path = Path()
        ..moveTo(at.dx - w, at.dy)
        ..quadraticBezierTo(at.dx - w / 2, at.dy - 6, at.dx, at.dy)
        ..quadraticBezierTo(at.dx + w / 2, at.dy - 6, at.dx + w, at.dy);
      canvas.drawPath(path, wave);
    }

    // The path: dots along a gentle curve from island to island.
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final unlocked = i + 1 <= reached;
      final color = unlocked
          ? const Color(0xFFFFF1BB)
          : const Color(0xFFECFBFF).withValues(alpha: 0.45);
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
              Paint()..color = const Color(0xFF317A85).withValues(alpha: 0.18),
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
  bool shouldRepaint(_SeaPainter old) =>
      old.reached != reached || old.paths != paths;
}

/// A sand island with the concept's emblem, its stars, name and levels.
class _Island extends StatelessWidget {
  const _Island({
    required this.island,
    required this.size,
    required this.marker,
    required this.onTap,
  });

  final MapIsland island;
  final double size;
  final Widget marker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locked = island.locked;
    final color = locked
        ? Colors.blueGrey.shade300
        : conceptColor(island.conceptId);
    final emblem = size * 0.62;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF0B3C49),
    );
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
                    // Shallow water, sand and grass.
                    _Ellipse(
                      width: size * 1.6,
                      height: size * 0.62,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    Positioned(
                      bottom: size * 0.06,
                      child: _Ellipse(
                        width: size * 1.36,
                        height: size * 0.5,
                        color: const Color(0xFFF6D88E),
                      ),
                    ),
                    Positioned(
                      bottom: size * 0.14,
                      child: _Ellipse(
                        width: size * 1.0,
                        height: size * 0.32,
                        color: locked
                            ? const Color(0xFFB7C4B0)
                            : const Color(0xFF7DCB6E),
                      ),
                    ),
                    // The emblem standing on the island.
                    Positioned(
                      bottom: size * 0.22,
                      child: Container(
                        width: emblem,
                        height: emblem,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(color, Colors.white, 0.28)!,
                              color,
                              Color.lerp(color, Colors.black, 0.12)!,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: emblem * 0.08,
                            color: island.current
                                ? const Color(0xFFFFD54F)
                                : Colors.white,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: island.current
                                  ? const Color(0xAAFFD54F)
                                  : Colors.black26,
                              blurRadius: island.current ? 18 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          locked
                              ? Icons.lock_rounded
                              : conceptIcon(island.conceptId),
                          size: emblem * 0.55,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Fog over islands the child can't reach yet.
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
              SizedBox(height: size * 0.04),
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
                      shadows: const [
                        Shadow(color: Colors.black26, blurRadius: 2),
                      ],
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
          ),
        ),
      ),
    );
  }
}

class _Ellipse extends StatelessWidget {
  const _Ellipse({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.all(Radius.elliptical(width, height)),
    ),
  );
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, -6 * Curves.easeInOut.transform(_controller.value)),
      child: child,
    ),
    child: widget.child,
  );
}
