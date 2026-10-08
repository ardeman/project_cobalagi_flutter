import 'package:cobalagi/core/widgets/glass_popups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a sheet keeps its content centred beside a camera cutout', (
    tester,
  ) async {
    // A phone held sideways, its camera cutout on the left.
    tester.view.physicalSize = const Size(2424, 1080);
    tester.view.devicePixelRatio = 2.625;
    tester.view.padding = const FakeViewPadding(left: 140);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showGlassSheet<void>(
                context: context,
                builder: (_) => const SafeArea(
                  child: Center(heightFactor: 1, child: Text('middle')),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getCenter(find.text('middle')).dx,
      moreOrLessEquals(screen.width / 2, epsilon: 1),
    );
  });
}
