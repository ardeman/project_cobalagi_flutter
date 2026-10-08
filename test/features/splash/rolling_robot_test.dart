import 'dart:io';
import 'dart:ui' as ui;

import 'package:cobalagi/features/splash/view/rolling_robot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpRobot(WidgetTester tester, {bool still = false}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: still),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(child: RollingRobot(semanticLabel: 'Robot')),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(RollingRobot));
    for (final part in ['head', 'body']) {
      await precacheImage(AssetImage('assets/images/robot_$part.png'), context);
    }
  });
  await tester.pump();
}

void main() {
  testWidgets('the robot rolls along', (tester) async {
    await pumpRobot(tester);
    final head = find.byType(Transform).last;
    final before = tester.getRect(head);
    await tester.pump(const Duration(milliseconds: 230));
    expect(tester.getRect(head), isNot(before), reason: 'it bounces');
    expect(find.bySemanticsLabel('Robot'), findsOneWidget);
    final out = Platform.environment['ROBOT_FRAMES'];
    if (out != null) {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).last,
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$out/frame$i.png').writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
    }
  });

  testWidgets('it parks after rolling for a while', (tester) async {
    await pumpRobot(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('it holds still when the system asks for less motion', (
    tester,
  ) async {
    await pumpRobot(tester, still: true);
    final head = find.byType(Transform).last;
    final before = tester.getRect(head);
    await tester.pump(const Duration(milliseconds: 230));
    expect(tester.getRect(head), before);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
