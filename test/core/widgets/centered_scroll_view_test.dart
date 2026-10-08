import 'package:cobalagi/core/widgets/centered_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a drag beside narrow content on a wide screen still scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CenteredScrollView(
            maxWidth: 720,
            centerVertically: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 60, child: Text('row $i')),
              ],
            ),
          ),
        ),
      ),
    );
    final first = tester.getTopLeft(find.text('row 0')).dy;
    // Far left, outside the 720 dp column.
    await tester.dragFrom(const Offset(40, 600), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('row 0')).dy, lessThan(first - 200));
    // The content stays centred and capped.
    expect(tester.getSize(find.byType(Column)).width, 720);
    expect(tester.getCenter(find.byType(Column)).dx, 640);
  });

  testWidgets('short content sits in the middle', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CenteredScrollView(child: Text('middle'))),
      ),
    );
    expect(tester.getCenter(find.text('middle')), const Offset(400, 300));
  });
}
