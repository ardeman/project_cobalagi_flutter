import 'package:cobalagi/features/adventure_map/view/map_connections.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final wide in [false, true]) {
    test('six-island connections avoid labels and turn smoothly ($wide)', () {
      const size = 110.0;
      final centres = [
        for (var i = 0; i < 6; i++)
          wide
              ? Offset(160 + i * 235, i.isEven ? 210 : 370)
              : Offset(i.isEven ? 120 : 280, 130 + i * size * 2.35),
      ];
      final labels = [
        for (final centre in centres)
          Rect.fromLTWH(
            centre.dx - size * 0.65,
            centre.dy + size * 0.25,
            size * 1.3,
            size * 0.6,
          ),
      ];
      final paths = mapConnections(
        centres: centres,
        islandSize: size,
        wide: wide,
      );
      expect(paths, hasLength(centres.length - 1));
      for (final path in paths) {
        final metric = path.computeMetrics().single;
        expect(metric.length, greaterThan(40));
        final start = metric.getTangentForOffset(0)!;
        final end = metric.getTangentForOffset(metric.length)!;
        expect(wide ? start.vector.dy : start.vector.dx, closeTo(0, 0.02));
        expect(wide ? end.vector.dy : end.vector.dx, closeTo(0, 0.02));
        for (var t = 0.0; t <= 1; t += 0.01) {
          final point = metric.getTangentForOffset(t * metric.length)!.position;
          expect(
            labels.any((label) => label.contains(point)),
            isFalse,
            reason: 'path must not pass through an island label',
          );
        }
      }
    });
  }
  test('empty and single-island maps have no connecting paths', () {
    for (final centres in [
      <Offset>[],
      [const Offset(100, 100)],
    ]) {
      expect(
        mapConnections(centres: centres, islandSize: 100, wide: true),
        isEmpty,
      );
    }
  });
}
