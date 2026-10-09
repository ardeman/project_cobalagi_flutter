import 'dart:async';

import 'package:cobalagi/core/widgets/paint_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a running animation never rebuilds the screen around it', (
    tester,
  ) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 500),
    );
    addTearDown(controller.dispose);
    var builds = 0;
    var taps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, constraints) {
            builds++;
            return Align(
              alignment: Alignment.topLeft,
              child: PaintTransition(
                animation: controller,
                transform: PaintTransition.translateY(100),
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const SizedBox.square(
                    dimension: 50,
                    child: ColoredBox(color: Color(0xFF000000)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    expect(builds, 1);

    unawaited(controller.repeat());
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(builds, 1, reason: 'paints only, no rebuild or layout');

    // Taps follow the child where it is drawn.
    controller.stop();
    controller.value = 1;
    await tester.pump();
    await tester.tapAt(const Offset(25, 125));
    expect(taps, 1);
    await tester.tapAt(const Offset(25, 25));
    expect(taps, 1, reason: 'it has moved away from its laid-out place');
  });
}
