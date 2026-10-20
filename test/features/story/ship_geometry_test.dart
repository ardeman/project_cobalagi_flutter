import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the ship geometry is half of branding/ship/ship.json', () {
    final json =
        jsonDecode(File('branding/ship/ship.json').readAsStringSync())
            as Map<String, Object?>;
    expect(json['size'], ShipGeometry.picture * 2);
    final views = json['views']! as Map<String, Object?>;
    for (final view in ShipView.values) {
      final v = views[view.name]! as Map<String, Object?>;
      final tank = v['tank']! as Map<String, Object?>;
      final cockpit = v['cockpit']! as Map<String, Object?>;
      Offset half(Object? point) {
        final p = (point! as List).cast<num>();
        return Offset(p[0] / 2, p[1] / 2);
      }

      final g = ShipGeometry.of(view);
      void same(Offset a, Offset b) {
        expect(a.dx, closeTo(b.dx, 0.01), reason: view.name);
        expect(a.dy, closeTo(b.dy, 0.01), reason: view.name);
      }

      same(g.base, half(v['base']));
      same(g.tankBottom, half(tank['bottom']));
      same(g.tankTop, half(tank['top']));
      same(g.cockpit, half(cockpit['centre']));
      expect(g.tankWidth, closeTo((tank['width']! as num) / 2, 0.01));
      expect(g.cockpitRadius, closeTo((cockpit['radius']! as num) / 2, 0.01));
      expect(File('assets/images/ship_${view.name}.webp').existsSync(), isTrue);
      expect(
        File('assets/images/ship_${view.name}_tank.webp').existsSync(),
        isTrue,
      );
    }
  });
}
