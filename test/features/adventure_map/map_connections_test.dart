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
              : Offset(i.isEven ? 108 : 292, 130 + i * size * 1.75),
      ];
      // Tablets: labels under the islands. Phones: beside them, on the side
      // away from the screen edge (right of left islands, left of right ones).
      final labels = [
        for (var i = 0; i < centres.length; i++)
          wide
              ? Rect.fromLTWH(
                  centres[i].dx - size * 0.65,
                  centres[i].dy + size * 0.25,
                  size * 1.3,
                  size * 0.6,
                )
              : Rect.fromLTWH(
                  i.isEven
                      ? centres[i].dx + size * 0.8 + 4
                      : centres[i].dx - size * 0.8 - 4 - size * 1.3,
                  centres[i].dy - size * 0.6,
                  size * 1.3,
                  size,
                ),
      ];
      final paths = mapConnections(
        centres: centres,
        islandSize: size,
        wide: wide,
      );
      expect(paths, hasLength(centres.length - 1));
      for (var i = 0; i < paths.length; i++) {
        final path = paths[i];
        final metric = path.computeMetrics().single;
        // Each path leaves one island's shore and lands on the next one's.
        final first = metric.getTangentForOffset(0)!.position;
        final last = metric.getTangentForOffset(metric.length)!.position;
        expect((first - centres[i]).distance, lessThan(size * 0.85));
        expect((last - centres[i + 1]).distance, lessThan(size * 0.85));
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
