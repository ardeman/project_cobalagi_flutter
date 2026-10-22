import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:cobalagi/features/story/view/ship_flight.dart';

void main() {
  group('keepFlyingShipInside', () {
    test('moves the ship back when its nose pokes out on the right', () {
      // A phone's right-hand planet: the tail at 344 of 393, nose right.
      final shift = keepFlyingShipInside(
        393,
        const Offset(344, 400),
        182,
        0.9,
        false,
      );
      expect(shift.dx, lessThan(0));
      expect(shift.dy, 0);
      // Moved once, it fits as it is.
      expect(
        keepFlyingShipInside(393, Offset(344 + shift.dx, 400), 182, 0.9, false),
        Offset.zero,
      );
    });

    test('moves a ship flying left back from the left edge', () {
      final shift = keepFlyingShipInside(
        393,
        const Offset(40, 400),
        182,
        -0.4,
        true,
      );
      expect(shift.dx, greaterThan(0));
    });

    test('leaves a ship in the middle of the map alone', () {
      expect(
        keepFlyingShipInside(393, const Offset(150, 400), 182, pi / 8, false),
        Offset.zero,
      );
    });
  });
}
